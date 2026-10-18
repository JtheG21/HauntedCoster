--!strict
-- Rare capture finisher cleanup proof (TASK-0054 AC2), fresh Play session (server data model):
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "RareCaptureFinisher" })
-- Runs the finisher once to the end through the real Heartbeat clock, once stepped by hand, and cancelled at
-- three points. After each: the effect folder is gone, Lighting has no leftover effects, no emitters are
-- left in Workspace, the peak emitter count stayed inside the budget, and the clock is disconnected.
-- Camera and input-lock cues need a client and are not exercised here.

local Lighting = game:GetService("Lighting")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local EMITTER_BUDGET = 3

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end

	local Finisher =
		require(StarterPlayer.StarterPlayerScripts:WaitForChild("Client"):WaitForChild("RareCaptureFinisher")) :: any
	local target = Instance.new("Part")
	target.Name = "FinisherScenarioTarget"
	target.Anchored = true
	target.Position = Vector3.new(0, 5, 0)
	target.Parent = Workspace

	local function emitters(): number
		local n = 0
		for _, d in Workspace:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				n += 1
			end
		end
		return n
	end

	local function run(label: string, opts: { reduced: boolean?, stopAt: number?, real: boolean? })
		local lightingBase = #Lighting:GetChildren()
		local workspaceBase = #Workspace:GetDescendants()
		local doneCalls = 0
		local player = Finisher.new(target, {
			reduced = opts.reduced,
			onDone = function()
				doneCalls += 1
			end,
		})
		local peak = 0
		if opts.real then
			player:play()
			while player.runner:isDone() == false do
				peak = math.max(peak, emitters())
				task.wait(0.1)
			end
		else
			local elapsed = 0
			while not player.runner:isDone() do
				player:step(0.1)
				elapsed += 0.1
				peak = math.max(peak, emitters())
				if opts.stopAt and elapsed >= opts.stopAt then
					player:stop()
				end
			end
		end
		task.wait(0.1) -- let the spawned onDone run
		check(`{label}: effect folder removed`, Workspace:FindFirstChild("FinisherFx") == nil)
		check(
			`{label}: Lighting back to baseline`,
			#Lighting:GetChildren() == lightingBase,
			`{#Lighting:GetChildren()} vs {lightingBase}`
		)
		check(
			`{label}: Workspace back to baseline`,
			#Workspace:GetDescendants() == workspaceBase,
			`{#Workspace:GetDescendants()} vs {workspaceBase}`
		)
		check(`{label}: no emitters left`, emitters() == 0, emitters())
		check(`{label}: peak emitters within budget`, peak <= EMITTER_BUDGET, `peak {peak}, budget {EMITTER_BUDGET}`)
		check(`{label}: clock disconnected`, player.conn == nil)
		check(`{label}: onDone called once`, doneCalls == 1, doneCalls)
	end

	run("real clock, full run", { real = true })
	run("stepped, reduced", { reduced = true })
	run("cancel in charge", { stopAt = 2 })
	run("cancel at flash 1", { stopAt = 4.1 })
	run("cancel in release", { stopAt = 9.5 })
	target:Destroy()

	local failed = 0
	for _, c in checks do
		if not c.ok then
			failed += 1
		end
	end
	return { passed = failed == 0, failed = failed, checks = checks }
end
