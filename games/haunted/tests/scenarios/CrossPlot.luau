--!strict
-- Two-player ownership scenario (TASK-0014 AC6, TASK-0016 seat griefing):
--  * A can't secure a capture at B's pen; B's roster is untouched; A can secure at their own pen.
--  * A sitting in B's front seat is ejected, and B can still ride and get paid.
--  * A can't exhibit B's monster.
--  * TASK-0021 AC3: with B at a crypt-opening house tier, tier-0 A still can't start a capture on a crypt
--    monster (the Bell Wraith inside the crypt, from inside and from outside its wall), nor on an Ashen
--    monster standing outside the crypt; B can. The calls go through the CaptureStart handler itself.
--   game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, { scenario = "CrossPlot" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local Variants = require(ReplicatedStorage.Shared.Config.Variants)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local PlotService = require(Services.PlotService) :: any
local CaptureService = require(Services.CaptureService) :: any
local TrainService = require(Services.TrainService) :: any
local ContainmentService = require(Services.ContainmentService) :: any
local EncounterService = require(Services.EncounterService) :: any
local Habitats = require(ReplicatedStorage.Shared.Config.Habitats)

return function(args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local inconclusive: { string } = {}
	local function finish()
		local failed = 0
		for _, c in checks do
			if not c.ok then
				failed += 1
			end
		end
		-- An inconclusive check is neither a pass nor a game failure: the run is flagged so it isn't counted.
		return {
			ok = failed == 0 and #inconclusive == 0,
			passed = #checks - failed,
			failed = failed,
			checks = checks,
			inconclusive = inconclusive,
			infra = if #inconclusive > 0 then true else nil,
		}
	end

	local timeout = (type(args) == "table" and args.timeout) or 60
	local t0 = os.clock()
	while #Players:GetPlayers() < 2 and os.clock() - t0 < timeout do
		task.wait(0.5)
	end
	local list = Players:GetPlayers()
	check("two players joined", #list >= 2, #list)
	if #list < 2 then
		-- Harness problem, not a game failure: the caller reruns once instead of spending a revision.
		local r: any = finish()
		r.infra = true
		return r
	end
	local a, b = list[1], list[2]
	local pa, pb = PlayerDataService.waitFor(a, 30), PlayerDataService.waitFor(b, 30)
	while (not PlotService.plotIndex(a) or not PlotService.plotIndex(b)) and os.clock() - t0 < timeout do
		task.wait(0.3)
	end
	local ia, ib = PlotService.plotIndex(a), PlotService.plotIndex(b)
	check("both have their own plot", ia ~= nil and ib ~= nil and ia ~= ib, `{ia} {ib}`)
	if not (pa and pb and ia and ib) then
		return finish()
	end
	-- Wait for both characters to exist and simulate (LES-0004).
	local function charOf(p: Player): Model
		return p.Character or p.CharacterAdded:Wait()
	end
	local ca, cb = charOf(a), charOf(b)
	task.wait(3)

	local function tp(p: Player, pos: Vector3)
		(p.Character :: Model):PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
		CaptureService.noteTeleport(p)
		task.wait(0.4)
	end
	-- Ownership is what this scenario tests, so captures skip the timed minigame: it missed under multiplayer
	-- load (three Studio processes on one machine) and failed runs for reasons unrelated to plots. FullLoop
	-- covers the real capture path.
	local function captureOne(p: Player): any
		CaptureService.carryForTest(p, "Wisp", Variants.Normal)
		return { outcome = if CaptureService.isCarrying(p) then "success" else "no carry" }
	end

	-- B secures one monster first (so B has something to protect).
	local rb = captureOne(b)
	check("B captured a monster", rb and rb.outcome == "success", rb and (rb.outcome or rb.reason))
	tp(b, World.plotToWorld(ib, World.Plot.pen))
	CaptureService.secure(b, ib)
	check("B owns one monster", #pb.owned == 1, #pb.owned)
	if #pb.owned ~= 1 then
		return finish() -- the ownership checks below need B's monster
	end

	-- A captures, then tries to secure at B's pen.
	task.wait(1)
	local ra = captureOne(a)
	check("A captured a monster", ra and ra.outcome == "success", ra and (ra.outcome or ra.reason))
	tp(a, World.plotToWorld(ib, World.Plot.pen))
	CaptureService.secure(a, ib)
	check("A can't secure at B's pen", #pa.owned == 0 and CaptureService.isCarrying(a), #pa.owned)
	check("B's roster untouched", #pb.owned == 1, #pb.owned)
	tp(a, World.plotToWorld(ia, World.Plot.pen))
	CaptureService.secure(a, ia)
	check("A secures at own pen", #pa.owned == 1, #pa.owned)

	-- Monster ids are per player ("m1" exists in both rosters), so an exhibit request always resolves
	-- against the caller's own roster: A placing "m1" exhibits A's monster and never touches B's.
	ContainmentService.setExhibit(a, 1, pb.owned[1].uid)
	local placed = pa.exhibits[1]
	check(
		"exhibit ids resolve to the caller's own roster",
		#pb.exhibits == 0 and (placed == nil or placed.uid == pa.owned[1].uid),
		`B exhibits={#pb.exhibits}`
	)
	check("B's roster still intact", #pb.owned == 1)

	-- Seat griefing: A sits in B's front seat and is ejected; B still rides and gets paid.
	local plotB = Workspace.Plots[`Plot{ib}`]
	local cart = plotB.Track:FindFirstChild("GhostCart")
	local front = cart and cart:FindFirstChild("FrontSeat") :: Seat?
	local humA = (a.Character :: Model):FindFirstChildOfClass("Humanoid") :: Humanoid
	if front then
		local seatedSeen = false
		local watch = front:GetPropertyChangedSignal("Occupant"):Connect(function()
			if front.Occupant == humA then
				seatedSeen = true
			end
		end)
		-- Positive control for the touch method (TASK-0035 AC1): an unguarded, enabled seat away from the
		-- plots. Touch-sitting is client-simulated physics and missed 2 of 3 runs on B's seat even with
		-- TrainService reverted (TEST-20261012-11), so a miss here makes the parked-seat check inconclusive,
		-- not a silent pass.
		local probe = Instance.new("Seat")
		probe.Name = "CrossPlotTouchProbe"
		probe.Anchored = true
		probe.Size = Vector3.new(2, 1, 2)
		probe.Position = World.plotToWorld(ia, World.Plot.spawn) + Vector3.new(0, 0.5, 12)
		probe.Parent = Workspace
		local touchWorks = false
		for _ = 1, 3 do
			tp(a, probe.Position + Vector3.new(0, 1.5, 0))
			local t1 = os.clock()
			while probe.Occupant ~= humA and os.clock() - t1 < 1.6 do
				task.wait(0.1)
			end
			if probe.Occupant == humA then
				touchWorks = true
				break
			end
		end
		probe:Destroy() -- also frees A (the SeatWeld goes with it)
		humA.Sit = false
		task.wait(0.5)
		-- Touch: A drops onto B's parked (disabled) seat and isn't seated (AUD-20261012-TASK-0025-02 N1).
		check("B's parked front seat is disabled (precondition)", front.Disabled == true, front.Disabled)
		tp(a, front.Position)
		task.wait(1)
		local untouched = not seatedSeen and front.Occupant ~= humA
		if touchWorks or not untouched then
			check(
				"touching B's parked front seat doesn't seat A",
				untouched,
				`seatedSeen={seatedSeen} occupant={front.Occupant}`
			)
		else
			table.insert(inconclusive, "touching B's parked front seat doesn't seat A (touch probe never seated A)")
		end
		-- Enabled (as during a ride): the server seats A directly, which is deterministic, and the owner
		-- guard must eject A (TASK-0035 AC2). Seat:Sit() goes through the same Occupant signal as a touch.
		front.Disabled = false
		seatedSeen = false
		front:Sit(humA)
		local t2 = os.clock()
		while not seatedSeen and os.clock() - t2 < 1 do
			task.wait(0.05)
		end
		task.wait(1)
		check(
			"A seated in B's enabled front seat, then ejected",
			seatedSeen and front.Occupant ~= humA,
			`seatedSeen={seatedSeen} occupant={front.Occupant}`
		)
		-- Parked: disabled again, so A can't touch-sit. A server Seat:Sit() can still seat through Disabled
		-- (engine behaviour, minimal repro in TEST-20261012-01), so the same guard must eject A.
		front.Disabled = true
		front:Sit(humA)
		task.wait(1)
		check("A forced into B's parked front seat doesn't keep it", front.Occupant ~= humA, front.Occupant)
		front.Disabled = true
		watch:Disconnect()
	else
		check("B's cart found", false)
	end
	local coinsB = pb.coins
	tp(b, World.plotToWorld(ib, Vector3.new(World.Plot.starterRoute[1].X, 0, World.Plot.starterRoute[1].Y)))
	TrainService.ride(b, ib)
	check("B rode and was paid despite A", pb.coins > coinsB and pb.stats.rides == 1, pb.coins - coinsB)

	-- TASK-0021 AC3: crypt capture gating by house tier, with a crypt-opening player present.
	if Habitats.active().id == "Cemetery" then
		pb.houseTier = 1 -- TEST SHORTCUT: B restored their house (tier 1 opens the crypt)
		pa.houseTier = 0
		local crypt = (Habitats.active().crypt :: any).rect
		local gateZ = (Habitats.active().crypt :: any).gateAt
		-- A Bell Wraith just inside the crypt gate (x2 side), so a player outside the wall is in range.
		local wraith =
			EncounterService.spawn("BellWraith", Variants.Normal, "Crypt", Vector3.new(crypt.x2 - 6, 0, gateZ))
		check("AC3: a Bell Wraith spawned in the crypt", wraith ~= nil)
		local function try(p: Player, e: any, at: Vector3, prep: (() -> ())?): string
			tp(p, at)
			task.wait(2.2) -- stay clear of the CaptureStart rate limit
			if prep then
				prep()
			end
			local r = CaptureService.startForTest(p, e.model)
			if r.ok then
				CaptureService.requestCancel(p)
				task.wait(0.5)
				return "ok"
			end
			return tostring(r.reason)
		end
		if wraith then
			-- The Wraith roams, so before each call it is put back 4 studs inside the gate.
			local function pin()
				wraith.model:PivotTo(CFrame.new(crypt.x2 - 4, wraith.root.Position.Y, gateZ))
			end
			local inside = try(a, wraith, Vector3.new(crypt.x2 - 10, 0, gateZ), pin)
			check(
				"AC3: tier-0 A can't capture the Bell Wraith from inside the crypt",
				inside:find("Restore your house") ~= nil,
				inside
			)
			-- Just outside the wall by the gate: A is in capture range, and only the crypt gate can refuse.
			local spot = Vector3.new(crypt.x2 + 2, 0, gateZ)
			local outside = try(a, wraith, spot, pin)
			check(
				"AC3: tier-0 A can't capture it from outside the wall",
				outside:find("Restore your house") ~= nil,
				outside
			)
			local byB = try(b, wraith, Vector3.new(crypt.x2 - 10, 0, gateZ), pin)
			check("AC3: tier-1 B can capture the Bell Wraith (control)", byB == "ok", byB)
			if wraith.alive then
				EncounterService.remove(wraith)
			end
		end
		-- An Ashen monster outside the crypt (no legal spawn does this; the gate must still hold).
		local openZone: any = nil
		for _, z in Habitats.active().zones do
			if not z.gated and z.spawns.Gentleman then
				openZone = z
				break
			end
		end
		local ashen = openZone
			and EncounterService.spawn(
				"Gentleman",
				"Ashen",
				openZone.id,
				Vector3.new((openZone.rect.x1 + openZone.rect.x2) / 2, 0, (openZone.rect.z1 + openZone.rect.z2) / 2)
			)
		check("AC3: an Ashen Gentleman spawned outside the crypt", ashen ~= nil)
		if ashen then
			local p0 = ashen.root.Position
			-- It roams too, and A's and B's tries take about 5 s, so it is put back before each call (TASK-0035:
			-- unpinned, B's control got "Get closer" in 2 of 3 runs).
			local function pinAshen()
				ashen.model:PivotTo(CFrame.new(p0))
			end
			local byA = try(a, ashen, Vector3.new(p0.X + 5, 0, p0.Z), pinAshen)
			check(
				"AC3: tier-0 A can't capture an Ashen monster outside the crypt",
				byA:find("Restore your house") ~= nil,
				byA
			)
			local byB2 = try(b, ashen, Vector3.new(p0.X + 5, 0, p0.Z), pinAshen)
			check("AC3: tier-1 B can capture the Ashen Gentleman (control)", byB2 == "ok", byB2)
			if ashen.alive then
				EncounterService.remove(ashen)
			end
		end
	else
		check("AC3: the Cemetery is active (test runs are pinned to it)", false, Habitats.active().id)
	end

	local _ = ca
	local _2 = cb
	return finish()
end
