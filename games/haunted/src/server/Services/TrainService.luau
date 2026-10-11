--!strict
-- Ghost train: builds each plot's track from its saved route (or the starter loop), runs server-driven
-- rides (anchored cart moved by CFrame, no physics), validates edited routes, and pays out only when
-- the server's own cart reaches the end with the owner still seated.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Rules = Shared:WaitForChild("Rules")
local World = require(Config:WaitForChild("World"))
local Economy = require(Config:WaitForChild("Economy"))
local Track = require(Config:WaitForChild("Track"))
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local TrackRules = require(Rules:WaitForChild("TrackRules"))
local ProfileRules = require(Rules:WaitForChild("ProfileRules"))
local EconomyRules = require(Rules:WaitForChild("EconomyRules"))
local Remotes = require(script.Parent.Parent.Remotes)
local Build = require(script.Parent.Parent.World.Build)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)
local PlotService = require(script.Parent.PlotService)

local TrainService = {}

type PlotTrain = {
	index: number,
	sampled: TrackRules.Sampled,
	pieces: { TrackRules.Piece },
	cart: Model?,
	frontSeat: Seat?,
	riding: boolean,
	prompt: ProximityPrompt?,
}

local RAIL_COLOR = Color3.fromRGB(60, 50, 70)
local TIE_COLOR = Color3.fromRGB(70, 50, 40)
local GLOW = Color3.fromRGB(170, 110, 255)

local started = false
local trains: { [number]: PlotTrain } = {}
-- Keyed by UserId so leaving and rejoining doesn't reset the paid-ride cooldown.
local lastPaid: { [number]: number } = {}
local rideCallbacks: { (Player, number) -> () } = {}

function TrainService.onRideCompleted(cb: (Player, number) -> ())
	table.insert(rideCallbacks, cb)
end

-- Unseat whoever is in `seat`. The character is client-simulated, so setting Humanoid.Sit from the server
-- isn't reliable; destroying the seat's weld (server-owned) always frees them.
local function unseat(seat: Seat)
	local occupant = seat.Occupant
	local weld = seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
	if occupant then
		occupant.Sit = false
		occupant.Jump = true
	end
end

local function starterPoints(): { TrackRules.P }
	local pts = {}
	for _, v in World.Plot.starterRoute do
		table.insert(pts, { x = v.X, z = v.Y })
	end
	return pts
end

local function toWorld(index: number, p: TrackRules.P, y: number): Vector3
	local o = World.PlotCenters[index]
	return Vector3.new(o.X + p.x, y, o.Z + p.z)
end

local function buildCart(parent: Instance): (Model, Seat)
	local cart = Instance.new("Model")
	cart.Name = "GhostCart"
	local base = Build.part({
		name = "Base",
		size = Vector3.new(4, 1, 6),
		cframe = CFrame.new(),
		color = Color3.fromRGB(35, 25, 45),
		material = Enum.Material.Wood,
		collide = false,
		parent = cart,
	})
	cart.PrimaryPart = base
	local function seat(name: string, z: number): Seat
		local s = Instance.new("Seat")
		s.Name = name
		s.Anchored = true
		s.Size = Vector3.new(3, 1, 2)
		s.CFrame = base.CFrame * CFrame.new(0, 1, z)
		s.Color = Color3.fromRGB(110, 30, 50)
		s.Material = Enum.Material.Fabric
		s.CanCollide = false
		s.Parent = cart
		return s
	end
	local front = seat("FrontSeat", -1.2)
	-- Touch-sitting is off for the owner's seat; TrainService enables it only for the owner's ride.
	front.Disabled = true
	local back = seat("GuestSeat", 1.6)
	back:SetAttribute("Guest", true)
	Build.part({
		name = "Skull",
		size = Vector3.new(2.2, 2, 1.4),
		cframe = base.CFrame * CFrame.new(0, 1.4, -3.2),
		color = Color3.fromRGB(230, 225, 210),
		material = Enum.Material.SmoothPlastic,
		collide = false,
		parent = cart,
	})
	local lamp = Build.part({
		name = "Lamp",
		size = Vector3.new(0.8, 0.8, 0.8),
		cframe = base.CFrame * CFrame.new(0, 2.6, -3.2),
		color = GLOW,
		material = Enum.Material.Neon,
		collide = false,
		parent = cart,
	})
	Build.light(lamp, GLOW, 14, 1.2)
	cart.Parent = parent
	return cart, front
end

local function cartAt(t: PlotTrain, d: number)
	if not t.cart then
		return
	end
	local p, dir = TrackRules.pointAt(t.sampled, d)
	local pos = toWorld(t.index, p, Track.RailHeight + 0.6)
	t.cart:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(dir.x, 0, dir.z)))
end

local function buildPiece(parent: Instance, kind: string, pos: Vector3, dir: TrackRules.P)
	local cf = CFrame.lookAt(pos, pos + Vector3.new(dir.x, 0, dir.z))
	if kind == "ScareArch" then
		for _, side in { -1, 1 } do
			Build.part({
				name = "ArchPost",
				size = Vector3.new(0.8, 9, 0.8),
				cframe = cf * CFrame.new(side * 3.4, 4.5, 0),
				color = Color3.fromRGB(40, 30, 30),
				material = Enum.Material.Wood,
				collide = false,
				parent = parent,
			})
		end
		Build.part({
			name = "ArchTop",
			size = Vector3.new(8, 1, 1),
			cframe = cf * CFrame.new(0, 9, 0),
			color = Color3.fromRGB(40, 30, 30),
			material = Enum.Material.Wood,
			collide = false,
			parent = parent,
		})
		local skull = Build.part({
			name = "ArchSkull",
			size = Vector3.new(2, 2, 2),
			cframe = cf * CFrame.new(0, 10.4, 0),
			color = Color3.fromRGB(235, 230, 215),
			shape = Enum.PartType.Ball,
			collide = false,
			parent = parent,
		})
		Build.light(skull, Color3.fromRGB(255, 80, 60), 14, 1.5)
	elseif kind == "FogTunnel" then
		local tunnel = Build.part({
			name = "FogTunnel",
			size = Vector3.new(7, 7, 10),
			cframe = cf * CFrame.new(0, 3.5, 0),
			color = Color3.fromRGB(60, 70, 90),
			material = Enum.Material.Glass,
			transparency = 0.6,
			collide = false,
			parent = parent,
		})
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(180, 190, 220)
		smoke.Opacity = 0.15
		smoke.RiseVelocity = 0.5
		smoke.Size = 4
		smoke.Parent = tunnel
	end
end

local function rebuild(index: number, points: { TrackRules.P }, pieces: { TrackRules.Piece })
	local plot = PlotService.plotModel(index)
	local folder = plot and plot:FindFirstChild("Track")
	if not (plot and folder) then
		return
	end
	local old = trains[index]
	if old and old.riding then
		return -- never rebuild under a moving cart
	end
	folder:ClearAllChildren()
	local sampled = TrackRules.sample(points)
	local sp = sampled.points
	local y = Track.RailHeight
	for i = 1, #sp do
		local a = toWorld(index, sp[i], y)
		local b = toWorld(index, sp[i % #sp + 1], y)
		local len = (b - a).Magnitude
		if len > 0.05 then
			local cf = CFrame.lookAt((a + b) / 2, b)
			-- Neighbouring rail segments overlap slightly to hide gaps on bends; alternate their
			-- thickness so the overlapping faces are never coplanar (z-fighting on straights).
			local thick = if i % 2 == 0 then 0.3 else 0.34
			for _, side in { -1.1, 1.1 } do
				Build.part({
					name = "Rail",
					size = Vector3.new(thick, thick, len + 0.2),
					cframe = cf * CFrame.new(side, 0, 0),
					color = RAIL_COLOR,
					material = Enum.Material.Metal,
					collide = false,
					parent = folder,
				})
			end
			Build.part({
				name = "Tie",
				size = Vector3.new(3.4, if i % 2 == 0 then 0.25 else 0.28, 0.7), -- alternate: ties overlap on tight bends
				cframe = cf * CFrame.new(0, -0.25, 0),
				color = TIE_COLOR,
				material = Enum.Material.Wood,
				collide = false,
				parent = folder,
			})
			if i % 4 == 0 then
				Build.part({
					name = "Support",
					size = Vector3.new(0.5, y, 0.5),
					cframe = CFrame.new(a.X, y / 2 - 0.2, a.Z),
					color = TIE_COLOR,
					material = Enum.Material.Wood,
					collide = false,
					parent = folder,
				})
			end
		end
	end
	-- Control-point markers (glowing posts) so the route reads clearly
	for _, p in points do
		local post = Build.part({
			name = "Waypoint",
			size = Vector3.new(0.4, 3, 0.4),
			cframe = CFrame.new(toWorld(index, p, 1.5)),
			color = GLOW,
			material = Enum.Material.Neon,
			collide = false,
			parent = folder,
		})
		post.Transparency = 0.3
	end
	for _, piece in pieces do
		local p = points[piece.i]
		if p then
			local _, dir = TrackRules.pointAt(sampled, 0)
			-- heading at the control point: find the nearest sample
			local best, bestI = math.huge, 1
			for si, s in sp do
				local d = (s.x - p.x) ^ 2 + (s.z - p.z) ^ 2
				if d < best then
					best, bestI = d, si
				end
			end
			local n = sp[bestI % #sp + 1]
			local dx, dz = n.x - sp[bestI].x, n.z - sp[bestI].z
			local m = math.sqrt(dx * dx + dz * dz)
			if m > 0 then
				dir = { x = dx / m, z = dz / m }
			end
			buildPiece(folder, piece.kind, toWorld(index, p, y), dir)
		end
	end
	-- Station platform at the start of the loop
	local start = toWorld(index, sp[1], 0)
	local station = Build.block(
		folder,
		"Station",
		Vector3.new(7, 1, 7),
		start.X,
		0,
		start.Z,
		Color3.fromRGB(55, 45, 60),
		Enum.Material.WoodPlanks
	)
	Build.billboard(station, "Ghost Train", GLOW, 6, 120, 1.1)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Ride"
	prompt.ActionText = "Ride Ghost Train"
	prompt.ObjectText = "Station"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = station

	local cart, front = buildCart(folder)
	local t: PlotTrain = {
		index = index,
		sampled = sampled,
		pieces = pieces,
		cart = cart,
		frontSeat = front,
		riding = false,
		prompt = prompt,
	}
	trains[index] = t
	cartAt(t, 0)
	prompt.Triggered:Connect(function(player)
		TrainService.ride(player, index)
	end)
	-- The guest seat is boarded with its own prompt, not by touch: the cart parks on the station, so a
	-- touch seat sat down anyone walking up to ride (found in the hands-on playtest, TEST-20261011-03).
	local guest = cart:FindFirstChild("GuestSeat")
	if guest and guest:IsA("Seat") then
		guest.Disabled = true
		local hop = Instance.new("ProximityPrompt")
		hop.Name = "RideAlong"
		hop.ActionText = "Hop in"
		hop.ObjectText = "Guest seat"
		hop.KeyboardKeyCode = Enum.KeyCode.R
		hop.GamepadKeyCode = Enum.KeyCode.ButtonY
		hop.MaxActivationDistance = 8
		hop.RequiresLineOfSight = false
		hop.Parent = guest
		hop.Triggered:Connect(function(player)
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 and not guest.Occupant and not humanoid.SeatPart then
				guest:Sit(humanoid)
			end
		end)
	end
	-- The front seat belongs to the plot owner: anyone else who walks into it is ejected, so nobody can
	-- block the owner's ride. (The guest seat is open to anyone for ride-alongs.)
	front:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = front.Occupant
		if not occupant then
			return
		end
		local owner = PlotService.ownerOf(index)
		local who = Players:GetPlayerFromCharacter(occupant.Parent)
		if who ~= owner then
			-- Deferred: the engine is still parenting the SeatWeld while this signal fires, so destroying
			-- it here is refused ("tried to set the parent of SeatWeld to NULL") and the griefer stays seated.
			task.defer(function()
				if front.Occupant == occupant then
					unseat(front)
				end
			end)
			if who then
				StateService.toast(who, "That's the owner's seat. Hop in the back to ride along!", "info")
			end
		end
	end)
end

local function exhibitInputs(profile: ProfileRules.Profile): { TrackRules.ExhibitInput }
	local out: { TrackRules.ExhibitInput } = {}
	local slots = Economy.HouseTiers[profile.houseTier + 1].exhibitSlots
	for _, e in profile.exhibits do
		local m = ProfileRules.findOwned(profile, e.uid)
		local pos = World.Plot.exhibitSlots[e.slot]
		if m and pos and e.slot <= slots then
			table.insert(out, {
				rarity = Monsters.Species[m.species].rarity :: string,
				variantMultiplier = Variants.multiplier(m.variant),
				x = pos.X,
				z = pos.Z,
			})
		end
	end
	return out
end

function TrainService.payoutPreview(player: Player): TrackRules.Payout?
	local i = PlotService.plotIndex(player)
	local profile = PlayerDataService.get(player)
	local t = i and trains[i]
	if not (t and profile) then
		return nil
	end
	local tier = Economy.HouseTiers[profile.houseTier + 1]
	return TrackRules.payout(t.sampled, t.pieces, tier.rideMultiplier, exhibitInputs(profile))
end

local function routeFor(profile: ProfileRules.Profile?): ({ TrackRules.P }, { TrackRules.Piece })
	if profile and profile.route then
		local v = TrackRules.validate(profile.route.points, profile.route.pieces, World.Plot.trackBounds)
		if v.ok then
			return profile.route.points, profile.route.pieces
		end
		warn("[Train] saved route failed validation; using the starter loop")
	end
	return starterPoints(), {}
end

function TrainService.ride(player: Player, index: number)
	local t = trains[index]
	if not t or t.riding then
		return
	end
	if PlotService.ownerOf(index) ~= player then
		StateService.toast(player, "Only the owner can start this ride. Hop in the back seat to ride along!", "info")
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = t.frontSeat
	if not (humanoid and seat and humanoid.Health > 0) then
		return
	end
	t.riding = true
	if t.prompt then
		t.prompt.Enabled = false
	end
	cartAt(t, 0)
	if seat.Occupant and seat.Occupant ~= humanoid then
		unseat(seat)
		task.wait(0.1)
	end
	seat.Disabled = false
	-- Roblox briefly refuses to re-seat a humanoid that just jumped out of a seat, so retry a few times.
	for _ = 1, 5 do
		if seat.Occupant == humanoid or humanoid.Health <= 0 then
			break
		end
		humanoid.Sit = false
		seat:Sit(humanoid)
		task.wait(0.4)
	end
	if seat.Occupant ~= humanoid then
		seat.Disabled = true
		t.riding = false
		if t.prompt then
			t.prompt.Enabled = true
		end
		StateService.toast(player, "Couldn't seat you. Try again.", "error")
		return
	end
	Remotes.event("RideState"):FireClient(player, { riding = true, length = TrackRules.loopLength(t.sampled) })
	local total = TrackRules.loopLength(t.sampled)
	local d = 0
	local completed = false
	local cancelled = false
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function(dt)
		if seat.Occupant ~= humanoid or not player.Parent then
			cancelled = true
			conn:Disconnect()
			return
		end
		d += Track.RideSpeed * dt
		if d >= total then
			completed = true
			conn:Disconnect()
			cartAt(t, 0)
			return
		end
		cartAt(t, d)
	end)
	while not completed and not cancelled do
		task.wait(0.1)
	end
	-- Eject riders and park the cart.
	for _, s in (t.cart and t.cart:GetChildren() or {}) :: { Instance } do
		if s:IsA("Seat") and s.Occupant then
			unseat(s)
		end
	end
	task.wait(0.2)
	seat.Disabled = true
	cartAt(t, 0)
	t.riding = false
	if t.prompt then
		t.prompt.Enabled = true
	end
	Remotes.event("RideState"):FireClient(player, { riding = false })
	if cancelled then
		StateService.toast(player, "Ride cancelled. No payout for leaving early.", "error")
		return
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return
	end
	local now = os.clock()
	if lastPaid[player.UserId] and now - lastPaid[player.UserId] < Economy.RideCooldownSeconds then
		local left = math.ceil(Economy.RideCooldownSeconds - (now - lastPaid[player.UserId]))
		StateService.toast(player, `What a ride! The guests need {left}s before the next paid ride.`, "info")
		return
	end
	lastPaid[player.UserId] = now
	local tier = Economy.HouseTiers[profile.houseTier + 1]
	local pay = TrackRules.payout(t.sampled, t.pieces, tier.rideMultiplier, exhibitInputs(profile))
	local firstRide = profile.stats.rides == 0
	PlayerDataService.update(player, function(p)
		EconomyRules.addCoins(p, pay.total)
		p.stats.rides += 1
		if not p.flags.bellHint then
			p.flags.bellHint = true
			p.journal.clues.TrainBell = true
		end
	end)
	StateService.toast(
		player,
		string.format(
			"Ride complete! +%d coins (base %d x house %.1f x route %.2f x exhibits +%d%%, %d in range)",
			pay.total,
			pay.base,
			pay.tier,
			pay.quality,
			math.floor(pay.exhibitBonus * 100 + 0.5),
			pay.counted
		),
		"success"
	)
	if firstRide then
		StateService.toast(
			player,
			"As the cart stops, a distant bell tolls from the graveyard... Investigate the Bell Tower.",
			"clue"
		)
	end
	for _, cb in rideCallbacks do
		task.spawn(cb, player, pay.total)
	end
end

local function onSubmitRoute(player: Player, points: any, pieces: any): (boolean, string?)
	if not Remotes.allow(player, "SubmitRoute", 0.5, 2) then
		return false, "Slow down"
	end
	local profile = PlayerDataService.get(player)
	local index = PlotService.plotIndex(player)
	if not (profile and index) then
		return false, "Still loading"
	end
	if not Economy.HouseTiers[profile.houseTier + 1].unlocksEditor then
		return false, "Restore your house to unlock the Track Editor"
	end
	local t = trains[index]
	if t and t.riding then
		return false, "Wait for the ride to finish"
	end
	local v = TrackRules.validate(points, pieces, World.Plot.trackBounds)
	if not v.ok then
		return false, v.reason
	end
	-- Store a cleaned copy (rounded) built from the validated input.
	local clean: { ProfileRules.RoutePoint } = {}
	for _, p in points do
		table.insert(clean, { x = math.floor(p.x * 10 + 0.5) / 10, z = math.floor(p.z * 10 + 0.5) / 10 })
	end
	local cleanPieces: { ProfileRules.RoutePiece } = {}
	for _, piece in (pieces or {}) :: { any } do
		table.insert(cleanPieces, { i = piece.i, kind = piece.kind })
	end
	-- Re-validate the rounded copy; rounding must not turn a valid route invalid.
	if not TrackRules.validate(clean, cleanPieces, World.Plot.trackBounds).ok then
		return false, "Route is too close to a limit; nudge a point and try again"
	end
	PlayerDataService.update(player, function(p)
		p.route = { points = clean, pieces = cleanPieces }
		p.flags.routeCustom = true
	end)
	rebuild(index, clean, cleanPieces)
	StateService.toast(player, "Route saved! Ride it to see your new payout.", "success")
	return true, nil
end

-- Shared by the SubmitRoute remote and the Studio test scenarios.
TrainService.submitRoute = onSubmitRoute

function TrainService.refresh(player: Player)
	StateService.markDirty(player)
end

function TrainService.start()
	if started then
		return
	end
	started = true
	for i = 1, #World.PlotCenters do
		rebuild(i, starterPoints(), {})
	end
	Remotes.func("SubmitRoute").OnServerInvoke = onSubmitRoute
	PlotService.onAssigned(function(player, index)
		local points, pieces = routeFor(PlayerDataService.get(player))
		rebuild(index, points, pieces)
		StateService.markDirty(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local index = player:GetAttribute("PlotIndex")
		if type(index) == "number" then
			task.defer(function()
				if not PlotService.ownerOf(index) then
					rebuild(index, starterPoints(), {})
				end
			end)
		end
	end)
	StateService.addProvider(function(player, snap)
		local pay = TrainService.payoutPreview(player)
		if pay then
			snap.ridePreview = pay
		end
		local i = PlotService.plotIndex(player)
		local t = i and trains[i]
		snap.riding = t ~= nil and t.riding
		local last = lastPaid[player.UserId]
		snap.rideCooldown = if last then math.max(0, Economy.RideCooldownSeconds - (os.clock() - last)) else 0
	end)
end

return TrainService
