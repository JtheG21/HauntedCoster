--!strict
-- Carry anti-cheat (TASK-0021): the server, not the client's WalkSpeed, decides whether a carry got home
-- honestly. The "cheats" are simulated by moving the character from the server WITHOUT noteTeleport, which
-- the server sees exactly as it sees a client that ignores its carry slowdown or teleports itself.
--  * AC1: sustained full speed, alternating bursts, and a teleport to the pen all drop the capture.
--  * AC2: a secure after the deadline fails (the capture breaks free).
--  * AC5: a server move during a carry (noteTeleport) gives no penalty; a noted move to the pen secures.
--  * AC4: an escaped Ashen monster only respawns in the Sealed Crypt (Cemetery, the pinned test habitat).
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "CarryGuard" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local Habitats = require(ReplicatedStorage.Shared.Config.Habitats)
local Variants = require(ReplicatedStorage.Shared.Config.Variants)
local EconomyRules = require(ReplicatedStorage.Shared.Rules.EconomyRules)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local PlotService = require(Services.PlotService) :: any
local CaptureService = require(Services.CaptureService) :: any
local EncounterService = require(Services.EncounterService) :: any

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local function finish(): { [string]: any }
		local failed = 0
		for _, c in checks do
			if not c.ok then
				failed += 1
			end
		end
		return { ok = failed == 0, passed = #checks - failed, failed = failed, checks = checks }
	end

	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local profile = PlayerDataService.waitFor(player, 30)
	local character = player.Character or player.CharacterAdded:Wait()
	local t0 = os.clock()
	while not PlotService.plotIndex(player) and os.clock() - t0 < 20 do
		task.wait(0.2)
	end
	local plotIndex = PlotService.plotIndex(player)
	check("profile and plot ready", profile ~= nil and plotIndex ~= nil)
	if not (profile and plotIndex) then
		return finish()
	end
	task.wait(2)
	-- A death respawns the character and would silently end a carry, so every step uses the current
	-- character and the run reports how many times it respawned (it should be 0).
	local respawns = 0
	local respawnConn = player.CharacterAdded:Connect(function()
		respawns += 1
	end)
	local function current(): (Model, Humanoid, BasePart)
		local c = player.Character or player.CharacterAdded:Wait()
		local h = c:WaitForChild("Humanoid", 5) :: Humanoid?
		local r = c:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if not (h and r) then
			error("the character lost its humanoid or root part (fell out of the world?)")
		end
		h.WalkSpeed = 0 -- the scenario does all the moving
		return c, h, r
	end
	local _ = character
	local pen = World.plotToWorld(plotIndex, World.Plot.pen)
	local carrySpeed = EconomyRules.walkSpeed(profile.speedLevel, true)
	-- Far from the pen on solid ground: another plot's spawn point (plots are built for every slot), so a walk
	-- home is long. The plaza and the ring road dropped the character out of the world in earlier runs.
	local away = World.plotToWorld(plotIndex % #World.PlotCenters + 1, World.Plot.spawn)

	-- A server move the game makes itself (noted) vs a move it only observes (a cheat).
	local function place(pos: Vector3)
		local c = current()
		CaptureService.noteTeleport(player)
		c:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
	end
	local function cheatTo(pos: Vector3)
		local c = current()
		c:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
	end
	-- Every step needs its own fresh carry: the speed budget grows with the carry's age, so a carry left
	-- over from an earlier step would have banked time and hide a cheat. A leftover carry is timed out
	-- (and its chase ended) through the real expiry paths first.
	local function newCarry(species: string?, variant: string?): boolean
		if CaptureService.isCarrying(player) then
			CaptureService.expireCarryForTest(player)
			task.wait(0.5)
		end
		if CaptureService.isChasing(player) then
			CaptureService.expireChaseForTest(player)
			task.wait(0.5)
		end
		place(away)
		task.wait(0.5)
		CaptureService.carryForTest(player, species or "Wisp", variant or Variants.Normal)
		task.wait(0.3)
		local info = CaptureService.carryForTestInfo(player)
		return info ~= nil and info.elapsed < 1
	end
	-- Moves the character from the server at `speeds[i]` studs/s for each 0.25 s step, zigzagging (the
	-- direction flips every 2 s) so it stays on the plaza instead of running off the map.
	local function run(speeds: { number }, dir: Vector3)
		for i, v in speeds do
			if not CaptureService.isCarrying(player) then
				return
			end
			local sign = if math.floor((i - 1) / 8) % 2 == 0 then 1 else -1
			local _, _, root = current()
			cheatTo(root.Position - Vector3.new(0, 3, 0) + dir * sign * v * 0.25)
			task.wait(0.25)
		end
	end
	-- What the server measured for the current carry (shown when a speed check fails).
	local function measured(): string
		local info = CaptureService.carryForTestInfo(player)
		if not info then
			return "no carry"
		end
		local _, _, root = current()
		return string.format(
			"travelled %.0f in %.1fs (budget %.0f), sampled=%s, at %.0f,%.0f",
			info.travelled,
			info.elapsed,
			carrySpeed * 1.35 * info.elapsed + 12,
			tostring(info.sampled),
			root.Position.X,
			root.Position.Z
		)
	end
	local function alive(): boolean
		local _, h = current()
		return h.Health > 0 and respawns == 0
	end

	-- Control: a carrier the server moves (noted) to the pen secures.
	local owned0 = #profile.owned
	check("control: carry started", newCarry())
	place(pen)
	task.wait(0.5)
	CaptureService.secure(player, plotIndex)
	check("control: a noted move to the pen secures", #profile.owned == owned0 + 1, #profile.owned - owned0)

	-- AC5: server moves during a carry are not speeding, however far.
	check("AC5: carry started", newCarry())
	-- Between plot spawn points (solid ground, well over 100 studs apart), and back to `away`.
	for i = 1, 4 do
		local plot = (plotIndex + i - 1) % #World.PlotCenters + 1
		place(if i == 4 then away else World.plotToWorld(plot, World.Plot.spawn))
		task.wait(0.6)
	end
	check("AC5: four long server moves left the carry intact", CaptureService.isCarrying(player) and alive())

	-- AC1: sustained full walking speed (the carry slowdown undone).
	check("AC1 sustained: carry started", newCarry())
	local fast = {}
	for i = 1, 40 do
		fast[i] = 16
	end
	run(fast, Vector3.new(1, 0, 0))
	check("AC1: 10 s at full speed drops the capture", not CaptureService.isCarrying(player) and alive(), measured())

	-- AC1: alternating bursts (2.5x then 1x the carry speed, average 1.75x; 2x/1x sat right at the budget).
	check("AC1 alternating: carry started", newCarry())
	local alternating = {}
	for i = 1, 80 do
		alternating[i] = carrySpeed * (if i % 2 == 0 then 2.5 else 1)
	end
	run(alternating, Vector3.new(0, 0, 1))
	check("AC1: alternating bursts drop the capture", not CaptureService.isCarrying(player) and alive(), measured())

	-- Control for the speed checks: an honest walk at the carry speed keeps the capture.
	check("control walk: carry started", newCarry())
	local honest = {}
	for i = 1, 24 do
		honest[i] = carrySpeed
	end
	run(honest, Vector3.new(-1, 0, 0))
	check("control: 6 s at the carry speed keeps the capture", CaptureService.isCarrying(player))

	-- AC1: teleporting to the pen and securing at once (before any tick sees the jump).
	local owned1 = #profile.owned
	check("AC1 teleport: carry started", newCarry())
	task.wait(1)
	local beforeJump = measured()
	cheatTo(pen)
	CaptureService.secure(player, plotIndex)
	check("AC1: a teleport to the pen doesn't secure", #profile.owned == owned1, beforeJump)
	check("AC1: the teleport dropped the capture", not CaptureService.isCarrying(player) and alive())

	-- AC2: a secure after the deadline, before the tick notices, is a timeout.
	check("AC2: carry started", newCarry())
	place(pen)
	task.wait(0.5)
	local owned2 = #profile.owned
	CaptureService.expireCarryForTest(player)
	CaptureService.secure(player, plotIndex)
	check("AC2: a secure after the deadline fails", #profile.owned == owned2, #profile.owned - owned2)
	check("AC2: the capture broke free instead", not CaptureService.isCarrying(player))
	if CaptureService.isChasing(player) then
		CaptureService.expireChaseForTest(player)
	end

	-- AC4: an escaped Ashen monster only goes back to the Sealed Crypt.
	check("AC4: the Cemetery (with its crypt) is active", Habitats.active().id == "Cemetery", Habitats.active().id)
	-- The Ashen Gentlemen in the world now, by encounter id, with their zone.
	local function ashen(): { [number]: string }
		local out = {}
		for _, m in Workspace.Monsters:GetChildren() do
			local e = EncounterService.get(m)
			if e and e.species == "Gentleman" and e.variant == "Ashen" and not e.fleeing then
				out[m:GetAttribute("EncounterId") :: number] = m:GetAttribute("Zone") :: string
			end
		end
		return out
	end
	local inCrypt, outside = 0, 0
	for _ = 1, 3 do
		-- Empty every zone, so the old "first zone that spawns Gentlemen" respawn would have had room
		-- outside the crypt (the regression this step must catch).
		EncounterService.clearWild()
		local before = ashen()
		-- The real escape path: a cheating carrier loses the Ashen Gentleman, which respawnEscaped sends home.
		if newCarry("Gentleman", "Ashen") then
			cheatTo(pen)
			task.wait(0.6)
		end
		for id, zone in ashen() do
			if before[id] == nil then
				if zone == "Crypt" then
					inCrypt += 1
				else
					outside += 1
				end
			end
		end
	end
	check("AC4: the escaped Ashen Gentlemen respawned in the crypt", inCrypt >= 3, inCrypt)
	check("AC4: none respawned outside the crypt", outside == 0, outside)

	check("the character never died or respawned during the run", respawns == 0, respawns)
	respawnConn:Disconnect()
	local _, h = current()
	h.WalkSpeed = EconomyRules.walkSpeed(profile.speedLevel, false)
	return finish()
end
