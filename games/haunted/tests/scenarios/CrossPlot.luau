--!strict
-- Two-player ownership scenario (TASK-0014 AC6, TASK-0016 seat griefing):
--  * A can't secure a capture at B's pen; B's roster is untouched; A can secure at their own pen.
--  * A sitting in B's front seat is ejected, and B can still ride and get paid.
--  * A can't exhibit B's monster.
--   game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, { scenario = "CrossPlot" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local CaptureRules = require(ReplicatedStorage.Shared.Rules.CaptureRules)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local PlotService = require(Services.PlotService) :: any
local CaptureService = require(Services.CaptureService) :: any
local TrainService = require(Services.TrainService) :: any
local ContainmentService = require(Services.ContainmentService) :: any

return function(args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local function finish()
		local failed = 0
		for _, c in checks do
			if not c.ok then
				failed += 1
			end
		end
		return { ok = failed == 0, passed = #checks - failed, failed = failed, checks = checks }
	end

	local timeout = (type(args) == "table" and args.timeout) or 60
	local t0 = os.clock()
	while #Players:GetPlayers() < 2 and os.clock() - t0 < timeout do
		task.wait(0.5)
	end
	local list = Players:GetPlayers()
	check("two players joined", #list >= 2, #list)
	if #list < 2 then
		return finish()
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
	local function catch(p: Player, target: Model): any
		local s = CaptureService.requestStart(p, target)
		if not s.ok then
			return s
		end
		local st = os.clock()
		local tgt = s.zoneCenter
		local r: any = nil
		for _ = 1, 3 do
			local dl = os.clock() + s.period * 2
			while os.clock() < dl do
				if math.abs(CaptureRules.needle(os.clock() - st, s.period) - tgt) < 0.02 then
					break
				end
				task.wait()
			end
			r = CaptureService.requestRelease(p)
			if r.outcome == "success" then
				break
			end
			tgt = r.zoneCenter or tgt
			task.wait(CaptureRules.MinReleaseGap + 0.05)
		end
		return r
	end
	local function monster(): Model?
		for _, m in Workspace.Monsters:GetChildren() do
			local zone = m:GetAttribute("Zone")
			if zone == "Gate" or zone == "OldRows" then
				return m :: Model
			end
		end
		return nil
	end

	-- B secures one monster first (so B has something to protect).
	local mb = monster()
	if mb and mb.PrimaryPart then
		tp(b, mb.PrimaryPart.Position - Vector3.new(0, 3, 0) + Vector3.new(4, 0, 0))
		local rb = catch(b, mb)
		check("B captured a monster", rb and rb.outcome == "success", rb and (rb.outcome or rb.reason))
		tp(b, World.PlotCenters[ib] + World.Plot.pen)
		CaptureService.secure(b, ib)
	end
	check("B owns one monster", #pb.owned == 1, #pb.owned)

	-- A captures, then tries to secure at B's pen.
	task.wait(1)
	local ma = monster()
	if ma and ma.PrimaryPart then
		tp(a, ma.PrimaryPart.Position - Vector3.new(0, 3, 0) + Vector3.new(4, 0, 0))
		local ra = catch(a, ma)
		check("A captured a monster", ra and ra.outcome == "success", ra and (ra.outcome or ra.reason))
	end
	tp(a, World.PlotCenters[ib] + World.Plot.pen)
	CaptureService.secure(a, ib)
	check("A can't secure at B's pen", #pa.owned == 0 and CaptureService.isCarrying(a), #pa.owned)
	check("B's roster untouched", #pb.owned == 1, #pb.owned)
	tp(a, World.PlotCenters[ia] + World.Plot.pen)
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
		tp(a, front.Position)
		-- Parked: the seat is disabled, so A can't sit at all.
		front:Sit(humA)
		task.wait(1)
		check("B's parked front seat refuses A", not seatedSeen and front.Occupant ~= humA, front.Occupant)
		-- Enabled (as during a ride): A does get seated, and the guard ejects A.
		front.Disabled = false
		front:Sit(humA)
		task.wait(1)
		check(
			"A seated in B's enabled front seat, then ejected",
			seatedSeen and front.Occupant ~= humA,
			`seatedSeen={seatedSeen} occupant={front.Occupant}`
		)
		front.Disabled = true
		watch:Disconnect()
	else
		check("B's cart found", false)
	end
	local coinsB = pb.coins
	tp(b, World.PlotCenters[ib] + Vector3.new(World.Plot.starterRoute[1].X, 0, World.Plot.starterRoute[1].Y))
	TrainService.ride(b, ib)
	check("B rode and was paid despite A", pb.coins > coinsB and pb.stats.rides == 1, pb.coins - coinsB)
	local _ = ca
	local _2 = cb
	return finish()
end
