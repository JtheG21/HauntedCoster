--!strict
-- Sequence runner cleanup proof (TASK-0053 AC2), run in a fresh Play session (server data model):
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "SequenceRunner" })
-- Drives the real SequencePlayer with the demo sequence through its own step clock, once to the end
-- and once cancelled mid-way, and checks descendants and connections return to the baseline and the
-- peak emitter count stays inside the budget. Camera cues need a client camera and are skipped here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local EMITTER_BUDGET = 3

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end

	local clientRoot = StarterPlayer.StarterPlayerScripts:WaitForChild("Client")
	local SequencePlayer = require(clientRoot:WaitForChild("SequencePlayer")) :: any
	local Handlers = require(clientRoot:WaitForChild("SequenceDemoHandlers")) :: any
	local Demo = require(ReplicatedStorage.Shared.Config.SequenceDemo)

	local anchor = Instance.new("Part")
	anchor.Name = "SequenceScenarioAnchor"
	anchor.Anchored = true
	anchor.Parent = Workspace

	local function counts(): (number, number)
		local emitters = 0
		for _, d in anchor:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				emitters += 1
			end
		end
		return #anchor:GetDescendants(), emitters
	end

	local function run(label: string, stopAt: number?)
		local baseDesc = counts()
		local peak = 0
		local doneCalls = 0
		local player = SequencePlayer.new(Demo, Handlers.make(anchor), function()
			doneCalls += 1
		end)
		local elapsed = 0
		while not player.runner:isDone() do
			player:step(0.1)
			elapsed += 0.1
			local _, emitters = counts()
			peak = math.max(peak, emitters)
			if stopAt and elapsed >= stopAt then
				player:stop()
			end
		end
		task.wait() -- let the spawned onDone run
		local desc, emitters = counts()
		check(`{label}: descendants back to baseline`, desc == baseDesc, `{desc} vs {baseDesc}`)
		check(`{label}: no emitters left`, emitters == 0, emitters)
		check(`{label}: peak emitters within budget`, peak <= EMITTER_BUDGET, `peak {peak}, budget {EMITTER_BUDGET}`)
		check(`{label}: clock disconnected`, player.conn == nil)
		check(`{label}: onDone called once`, doneCalls == 1, doneCalls)
		return peak
	end

	local fullPeak = run("full run", nil)
	check("full run reached the burst", fullPeak >= 2, fullPeak)
	run("cancel mid-aura", 1.5)
	run("cancel during burst", 3.4)
	anchor:Destroy()

	local failed = 0
	for _, c in checks do
		if not c.ok then
			failed += 1
		end
	end
	return { passed = failed == 0, failed = failed, checks = checks }
end
