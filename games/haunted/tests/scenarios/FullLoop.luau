--!strict
-- End-to-end server scenario for the GAME-002 MVP loop, driven through the same service entry points the
-- remotes and prompts use. Run from a plugin/command bar:
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "FullLoop" })
-- Some steps shortcut waiting (e.g. back-dating acclimation, granting test coins); each is labelled.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared.Config.World)
local Economy = require(Shared.Config.Economy)
local CaptureRules = require(Shared.Rules.CaptureRules)
local EconomyRules = require(Shared.Rules.EconomyRules)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local PlotService = require(Services.PlotService) :: any
local LandmarkService = require(Services.LandmarkService) :: any
local CaptureService = require(Services.CaptureService) :: any
local TrainService = require(Services.TrainService) :: any
local EconomyService = require(Services.EconomyService) :: any
local ContainmentService = require(Services.ContainmentService) :: any

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end

	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local profile = PlayerDataService.waitFor(player, 30)
	check("profile loads", profile ~= nil)
	if not profile then
		return { ok = false, checks = checks }
	end
	check(
		"persistence mode reported",
		PlayerDataService.persistence(player) ~= "loading",
		PlayerDataService.persistence(player)
	)
	local t0 = os.clock()
	while not PlotService.plotIndex(player) and os.clock() - t0 < 10 do
		task.wait(0.2)
	end
	local plotIndex = PlotService.plotIndex(player)
	check("plot assigned", plotIndex ~= nil, plotIndex)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	task.wait(1)
	local home = World.PlotCenters[plotIndex]
	check(
		"spawned at home plot",
		(Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(home.X, 0, home.Z)).Magnitude < 60,
		root.Position
	)
	check("starter train exists", Workspace.Plots[`Plot{plotIndex}`].Track:FindFirstChild("GhostCart") ~= nil)
	check(
		"starter ride has its Scare Arch (Round 20 Q4)",
		Workspace.Plots[`Plot{plotIndex}`].Track:FindFirstChild("ArchPost") ~= nil
	)
	local preview = TrainService.payoutPreview(player)
	check("starter ride payout preview", preview ~= nil and preview.total > 0, preview and preview.total)

	local function tp(pos: Vector3)
		character:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
		CaptureService.noteTeleport(player) -- server moves aren't speeding
		task.wait(0.3)
	end

	-- Landmark
	tp((World.landmarkById("Angel") :: any).position + Vector3.new(0, 0, 6))
	LandmarkService.investigate(player, "Angel")
	check("landmark records clue", profile.journal.clues.Angel == true)
	local before = 0
	for _ in profile.journal.clues do
		before += 1
	end
	LandmarkService.investigate(player, "Angel")
	local after = 0
	for _ in profile.journal.clues do
		after += 1
	end
	check("repeat investigate adds nothing", before == after)
	tp(Vector3.new(0, 0, 0))
	LandmarkService.investigate(player, "Hearse")
	check("far-away investigate rejected", profile.journal.clues.Hearse ~= true)
	LandmarkService.investigate(player, "BellTower")
	check("bell tower locked before first ride", profile.flags.bellClue ~= true)

	-- Find a Wisp and capture it
	local function findMonster(species: string, zone: string?): Model?
		for _, m in Workspace.Monsters:GetChildren() do
			if m:GetAttribute("Species") == species and (zone == nil or m:GetAttribute("Zone") == zone) then
				return m :: Model
			end
		end
		return nil
	end
	local function catch(target: Model): any
		local s = CaptureService.requestStart(player, target)
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
			r = CaptureService.requestRelease(player)
			if r.outcome ~= "hit" then
				break -- success, or a miss/flee/cancel that ended the session
			end
			tgt = r.zoneCenter or tgt
			task.wait(CaptureRules.MinReleaseGap + 0.05)
		end
		return r
	end
	local wisp = findMonster("Wisp", "Gate") or findMonster("Wisp")
	check("a Wisp is spawned", wisp ~= nil)
	if not wisp then
		return { ok = false, checks = checks }
	end
	local far = CaptureService.requestStart(player, wisp)
	check("capture from far away rejected", far.ok == false, far.reason)
	local forged = CaptureService.requestStart(player, Workspace.Plots)
	check("capture of a non-monster rejected", forged.ok == false, forged.reason)
	tp((wisp.PrimaryPart :: BasePart).Position - Vector3.new(0, 4, 0) + Vector3.new(4, 0, 0))
	local released = catch(wisp)
	check(
		"well-timed release captures",
		released ~= nil and released.outcome == "success",
		released and (released.outcome or released.reason)
	)
	check("carrying after capture", CaptureService.isCarrying(player))
	check(
		"carry slows walk speed",
		math.abs(humanoid.WalkSpeed - EconomyRules.walkSpeed(0, true)) < 0.01,
		humanoid.WalkSpeed
	)
	local again = CaptureService.requestStart(player, findMonster("Wisp") or wisp)
	check("cannot start a second capture while carrying", again.ok == false, again.reason)

	-- Secure: wrong pen, then own pen
	local otherIndex = if plotIndex == 1 then 2 else 1
	tp(World.PlotCenters[otherIndex] + World.Plot.pen)
	CaptureService.secure(player, otherIndex)
	check("securing at another plot's pen rejected", #profile.owned == 0 and CaptureService.isCarrying(player))
	tp(home + World.Plot.pen)
	CaptureService.secure(player, plotIndex)
	check("secured at own pen", #profile.owned == 1, #profile.owned)
	check("onboarding reward granted", profile.coins >= Economy.OnboardingReward, profile.coins)
	check(
		"speed restored after securing",
		math.abs(humanoid.WalkSpeed - Economy.BaseWalkSpeed) < 0.01,
		humanoid.WalkSpeed
	)
	check("journal marks Wisp caught", profile.journal.caught.Wisp == true)

	-- Acclimation and income (TEST SHORTCUT: back-date acquisition instead of waiting 30 s)
	local c0 = profile.coins
	task.wait(2.2)
	check("no income while acclimating", profile.coins == c0, profile.coins - c0)
	profile.owned[1].acquiredAt -= Economy.AcclimationSeconds + 1
	task.wait(2.2)
	check("income after acclimation", profile.coins > c0, profile.coins - c0)

	-- Purchases
	local purchase = EconomyService.purchase
	profile.coins = 10
	local okLow, whyLow = purchase(player, "house", profile.houseTier)
	check("house purchase rejected without funds", okLow == false and profile.houseTier == 0, whyLow)
	local okBad = purchase(player, "freeMoney", 0)
	check("unknown item rejected", okBad == false)
	-- TEST SHORTCUT: grant coins to skip saving up
	profile.coins = 400
	task.wait(0.6) -- purchase rate limit
	local okSpeed = purchase(player, "speed", profile.speedLevel)
	check(
		"speed upgrade purchased",
		okSpeed == true and profile.speedLevel == 1 and profile.coins >= 325 and profile.coins < 335,
		profile.coins
	)
	check(
		"speed applied",
		math.abs(humanoid.WalkSpeed - (Economy.BaseWalkSpeed + Economy.SpeedPerLevel)) < 0.01,
		humanoid.WalkSpeed
	)
	task.wait(0.6)
	local coinsBeforeDup = profile.coins
	local okDup = purchase(player, "speed", 0) -- a repeated click still carrying the old level
	check(
		"duplicate purchase (stale level) rejected",
		okDup == false and profile.speedLevel == 1 and profile.coins == coinsBeforeDup
	)
	task.wait(0.6)
	local okHouse = purchase(player, "house", profile.houseTier)
	-- Passive income keeps ticking, so allow a few coins above the exact 75 left after paying.
	check(
		"house tier 1 purchased",
		okHouse == true and profile.houseTier == 1 and profile.coins >= 75 and profile.coins < 85,
		profile.coins
	)

	local houseFolder = Workspace.Plots[`Plot{plotIndex}`]:FindFirstChild("House")
	check("house model rebuilt for tier 1", houseFolder ~= nil and houseFolder:FindFirstChild("Manor") ~= nil)

	-- Track editor
	local submit = TrainService.submitRoute
	local okBadRoute, whyBad = submit(player, { { x = 0, z = 0 }, { x = 10, z = 0 }, { x = 0, z = 10 } }, {})
	check("invalid route rejected", okBadRoute == false and profile.route == nil, whyBad)
	task.wait(2.1)
	local custom = {
		{ x = -14, z = -36 },
		{ x = 10, z = -38 },
		{ x = 40, z = -36 },
		{ x = 44, z = -10 },
		{ x = 28, z = -16 },
		{ x = 22, z = 6 },
		{ x = -2, z = 8 },
		{ x = -14, z = -10 },
	}
	local okRoute, whyRoute = submit(player, custom, { { i = 2, kind = "ScareArch" } })
	check("valid custom route accepted", okRoute == true and profile.route ~= nil, whyRoute)
	check("routeCustom flag set", profile.flags.routeCustom == true)
	task.wait(2.1)
	local okOut, whyOut = submit(
		player,
		{ { x = 100, z = 0 }, { x = 120, z = 0 }, { x = 120, z = 20 }, { x = 100, z = 20 } },
		{}
	)
	check("out-of-bounds route rejected", okOut == false, whyOut)
	check("last valid route kept after rejection", profile.route ~= nil and #profile.route.points == #custom)

	-- Exhibit
	local setExhibit = ContainmentService.setExhibit
	local okLocked = setExhibit(player, 4, profile.owned[1].uid)
	check("locked exhibit slot rejected", okLocked == false)
	local okNotMine = setExhibit(player, 1, "m999")
	check("exhibiting an unowned monster rejected", okNotMine == false)
	local okEx = setExhibit(player, 1, profile.owned[1].uid)
	check("exhibit placed", okEx == true and #profile.exhibits == 1)
	local pay = TrainService.payoutPreview(player)
	check("exhibit near track counts toward payout", pay ~= nil and pay.counted >= 1, pay and pay.counted)

	-- Ride: leaving the seat mid-ride cancels with no payout
	tp(home + Vector3.new(custom[1].x, 0, custom[1].z))
	local coinsBeforeCancel = profile.coins
	task.spawn(TrainService.ride, player, plotIndex)
	task.wait(2.5)
	local seatPart = humanoid.SeatPart
	check(
		"the ride had started before leaving (seated in the front seat)",
		seatPart ~= nil and seatPart.Name == "FrontSeat",
		seatPart and seatPart:GetFullName()
	)
	humanoid.Sit = false
	humanoid.Jump = true
	task.wait(1.5)
	check(
		"leaving the seat mid-ride pays nothing",
		profile.coins == coinsBeforeCancel and profile.stats.rides == 0,
		profile.coins - coinsBeforeCancel
	)
	task.wait(1)

	local coinsBeforeRide = profile.coins
	tp(home + Vector3.new(custom[1].x, 0, custom[1].z))
	TrainService.ride(player, plotIndex)
	check("ride paid out", profile.coins > coinsBeforeRide, profile.coins - coinsBeforeRide)
	check("ride counted", profile.stats.rides == 1)
	check("first ride reveals the bell clue", profile.flags.bellHint == true)
	task.wait(1)
	local coinsBeforeSecond = profile.coins
	TrainService.ride(player, plotIndex)
	check(
		"immediate second ride is not paid (cooldown)",
		profile.coins == coinsBeforeSecond,
		profile.coins - coinsBeforeSecond
	)

	-- Bell Tower now gives the rare clue
	task.wait(1)
	tp((World.landmarkById("BellTower") :: any).position + Vector3.new(0, 0, 8))
	LandmarkService.investigate(player, "BellTower")
	check("bell tower clue after first ride", profile.flags.bellClue == true)
	-- The clue must actually bring the Bell Wraith, even though Gentlemen filled the Crypt long before
	-- (1-in-3 roll per 4 s spawn tick, so 60 s fails by chance about 0.2% of the time).
	local wraithAt = os.clock()
	while not Workspace.Monsters:FindFirstChild("BellWraith") and os.clock() - wraithAt < 60 do
		task.wait(1)
	end
	check(
		"Bell Wraith spawns in the Crypt after the clue",
		Workspace.Monsters:FindFirstChild("BellWraith") ~= nil,
		string.format("%.0fs", os.clock() - wraithAt)
	)

	-- Escape never touches owned monsters
	local ownedBefore = #profile.owned
	local victim = findMonster("Hound") or findMonster("Wisp")
	if victim and victim.PrimaryPart then
		tp(victim.PrimaryPart.Position + Vector3.new(4, 0, 0))
		local r2 = catch(victim)
		check("second capture succeeded", r2 ~= nil and r2.outcome == "success", r2 and (r2.outcome or r2.reason))
		if r2 and r2.outcome == "success" then
			humanoid.Health = 0
			task.wait(1)
			check("death while carrying = escape", not CaptureService.isCarrying(player))
			check("escape kept owned monsters", #profile.owned == ownedBefore, #profile.owned)
			check("escape counted", profile.stats.escapes >= 1)
		end
	end

	-- After respawning: home spawn and speed upgrade still applied
	local newChar = player.Character
	local t1 = os.clock()
	while (newChar == character or not newChar) and os.clock() - t1 < 10 do
		task.wait(0.2)
		newChar = player.Character
	end
	if newChar and newChar ~= character then
		character = newChar
		humanoid = newChar:WaitForChild("Humanoid") :: Humanoid
		root = newChar:WaitForChild("HumanoidRootPart") :: BasePart
		task.wait(1.5)
		check(
			"respawn keeps speed upgrade",
			math.abs(humanoid.WalkSpeed - (Economy.BaseWalkSpeed + Economy.SpeedPerLevel)) < 0.01,
			humanoid.WalkSpeed
		)
		check(
			"respawn lands at home",
			(Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(home.X, 0, home.Z)).Magnitude < 60,
			root.Position
		)
	else
		check("character respawned", false)
	end

	-- Round 20 Q2: a missed press startles the monster; it hops away and the attempt resumes later.
	local third = findMonster("Wisp") or findMonster("Hound")
	if third and third.PrimaryPart then
		tp(third.PrimaryPart.Position - Vector3.new(0, 3, 0) + Vector3.new(4, 0, 0))
		local s3 = CaptureService.requestStart(player, third)
		if s3.ok then
			local st = os.clock()
			local offZone = if s3.zoneCenter > 0.5 then 0.02 else 0.98
			while
				os.clock() - st < s3.period * 2
				and math.abs(CaptureRules.needle(os.clock() - st, s3.period) - offZone) > 0.03
			do
				task.wait()
			end
			local p0 = (third.PrimaryPart :: BasePart).Position
			local miss = CaptureService.requestRelease(player)
			check("off-zone press is a miss", miss.outcome == "miss", miss.outcome)
			check("a miss ends the meter session", CaptureService.requestRelease(player).outcome == "none")
			local skittish = CaptureService.requestStart(player, third)
			check("no instant retry while startled", skittish.ok == false, skittish.reason)
			task.wait(1)
			local hop = Vector3.new(
				(third.PrimaryPart :: BasePart).Position.X - p0.X,
				0,
				(third.PrimaryPart :: BasePart).Position.Z - p0.Z
			).Magnitude
			check("startled monster hopped 8-14 studs", hop >= 7 and hop <= 15, string.format("%.1f", hop))
			tp(third.PrimaryPart.Position - Vector3.new(0, 3, 0) + Vector3.new(4, 0, 0))
			local again3 = CaptureService.requestStart(player, third)
			check(
				"retry after the hop keeps the miss",
				again3.ok == true and again3.misses == miss.misses,
				again3.misses
			)
			if again3.ok then
				-- Close this session so catch() can start its own (the counters are kept on the monster).
				CaptureService.requestCancel(player)
			end
		else
			check("third capture start", false, s3.reason)
		end
	end

	-- Round 20 Q1: the timer runs out -> it breaks free and runs; grab it back once, then it goes home.
	if third and third.Parent and third.PrimaryPart then
		tp(third.PrimaryPart.Position - Vector3.new(0, 3, 0) + Vector3.new(4, 0, 0))
		local r3 = catch(third)
		if r3 and r3.outcome == "success" then
			local ownedB, coinsB, escB = #profile.owned, profile.coins, profile.stats.escapes
			CaptureService.expireCarryForTest(player)
			task.wait(0.6)
			check("timer expiry = escape", not CaptureService.isCarrying(player))
			check("timer expiry starts a chase", CaptureService.isChasing(player))
			check("a chase isn't a lost escape yet", profile.stats.escapes == escB, profile.stats.escapes)
			local runner = CaptureService.chaseTarget(player)
			check("the escaped monster is in the world", runner ~= nil and runner.Parent ~= nil)
			local busy = CaptureService.requestStart(player, findMonster("Wisp") or third)
			check("no new capture during a chase", busy.ok == false, busy.reason)
			if runner and runner.PrimaryPart then
				local rp = runner.PrimaryPart.Position
				local pos = root.Position
				tp(Vector3.new(rp.X, 0, rp.Z) + (Vector3.new(pos.X - rp.X, 0, pos.Z - rp.Z).Unit * 40))
				check("grab from too far rejected", CaptureService.grab(player) == false)
				task.wait(1)
				check("it runs away", (runner.PrimaryPart.Position - rp).Magnitude > 3)
				local rp2 = runner.PrimaryPart.Position
				tp(Vector3.new(rp2.X, 0, rp2.Z))
				check("grab when close", CaptureService.grab(player) == true)
				check("a second grab does nothing", CaptureService.grab(player) == false)
				check("carrying again after the grab", CaptureService.isCarrying(player))
				check("the fleeing model is gone", runner.Parent == nil)
				CaptureService.expireCarryForTest(player)
				task.wait(0.6)
				check(
					"second timeout sends it home (no second chase)",
					not CaptureService.isCarrying(player) and not CaptureService.isChasing(player)
				)
				check("lost escape counted", profile.stats.escapes == escB + 1, profile.stats.escapes)
			end
			check(
				"escape kept owned monsters and coins",
				#profile.owned == ownedB and profile.coins >= coinsB,
				`{#profile.owned} {profile.coins - coinsB}`
			)
		else
			check("third capture succeeded", false, r3 and (r3.outcome or r3.reason))
		end
	end

	-- A chase that runs out: the monster returns to its habitat.
	local fourth = findMonster("Wisp") or findMonster("Hound")
	if fourth and fourth.PrimaryPart then
		tp(fourth.PrimaryPart.Position - Vector3.new(0, 3, 0) + Vector3.new(4, 0, 0))
		local r4 = catch(fourth)
		if r4 and r4.outcome == "success" then
			local escB = profile.stats.escapes
			CaptureService.expireCarryForTest(player)
			task.wait(0.6)
			local runner = CaptureService.chaseTarget(player)
			if runner and runner.PrimaryPart then
				tp(Vector3.new(runner.PrimaryPart.Position.X, 0, runner.PrimaryPart.Position.Z))
			end
			CaptureService.expireChaseForTest(player)
			check("grab after the deadline rejected (even when close)", CaptureService.grab(player) == false)
			task.wait(0.6)
			check("chase expiry ends the chase", not CaptureService.isChasing(player))
			check("chase expiry removes the runner", runner == nil or runner.Parent == nil)
			check("chase expiry counts a lost escape", profile.stats.escapes == escB + 1, profile.stats.escapes)
		else
			check("fourth capture succeeded", false, r4 and (r4.outcome or r4.reason))
		end
	end

	-- Mid-ride handover: a rebuild requested during a ride (as when the plot changes owner) must wait
	-- for the ride to end, then build the CURRENT owner's route. Simulated here by changing the owner's
	-- saved route mid-ride and asking for the owner rebuild, the same path PlotService.onAssigned uses.
	local trackFolder = Workspace.Plots[`Plot{plotIndex}`].Track
	local function railCount(): number
		local n = 0
		for _, c in trackFolder:GetChildren() do
			if c.Name == "Rail" then
				n += 1
			end
		end
		return n
	end
	local savedRoute = profile.route
	local railsCustom = railCount()
	-- The character respawned earlier in this scenario: use the current humanoid.
	local current = player.Character :: Model
	local hum = current:FindFirstChildOfClass("Humanoid") :: Humanoid
	current:PivotTo(CFrame.new(home + Vector3.new(custom[1].x, 3, custom[1].z)))
	CaptureService.noteTeleport(player)
	task.wait(0.3)
	task.spawn(TrainService.ride, player, plotIndex)
	task.wait(2.5)
	local seatedForHandover = hum.SeatPart ~= nil and hum.SeatPart.Name == "FrontSeat"
	profile.route = nil -- the "new owner" has no custom route: the starter loop
	TrainService.rebuildForOwner(plotIndex)
	task.wait(0.3)
	check(
		"handover mid-ride: no rebuild under the moving cart",
		seatedForHandover and railCount() == railsCustom,
		`seated={seatedForHandover} rails {railCount()} vs {railsCustom}`
	)
	hum.Sit = false
	hum.Jump = true
	task.wait(1.5)
	local railsAfter = railCount()
	check(
		"handover: the current owner's route is built when the ride ends",
		railsAfter > 0 and railsAfter ~= railsCustom,
		`rails {railsAfter} (custom was {railsCustom})`
	)
	profile.route = savedRoute
	TrainService.rebuildForOwner(plotIndex)

	task.wait(2)
	check("tutorial complete after the bell step (12 steps)", profile.tutorialStep >= 13, profile.tutorialStep)

	local failed = 0
	for _, c in checks do
		if not c.ok then
			failed += 1
		end
	end
	return { ok = failed == 0, passed = #checks - failed, failed = failed, checks = checks }
end
