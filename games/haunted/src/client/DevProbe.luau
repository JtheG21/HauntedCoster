--!strict
-- Studio-only exploit probe (TASK-0013 AC3). Does nothing unless running in Studio AND the server-side
-- ExploitProbe scenario has armed it (ReplicatedStorage attribute HC_RunProbe). It sends forged, malformed
-- and spammed requests through the REAL remotes, like an exploiter would, and reports what came back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DevProbe = {}

local function call(remotes: Instance, name: string, ...: any): (boolean, any, any)
	local f = remotes:FindFirstChild(name) :: RemoteFunction?
	if not f then
		return false, "missing", nil
	end
	local ok, r1, r2 = pcall(f.InvokeServer, f, ...)
	return ok, r1, r2
end

local function run(): { [string]: any }
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local report: { [string]: any } = {}

	local _, rel = call(remotes, "CaptureRelease")
	report.releaseWithoutSession = type(rel) == "table" and rel.outcome or tostring(rel)

	-- Each forged argument separately (a nil inside a table literal would be skipped by iteration).
	local forged: { () -> any } = {
		function()
			return nil
		end,
		function()
			return "Wisp"
		end,
		function()
			return 123
		end,
		function()
			return workspace
		end,
		function()
			return workspace:FindFirstChild("Plots")
		end,
	}
	local starts: { boolean } = {}
	for i, make in forged do
		local ok, r = call(remotes, "CaptureStart", make())
		starts[i] = ok and type(r) == "table" and r.ok == false
		task.wait(0.6) -- stay under the CaptureStart rate limit so each case tests its own validation
	end
	report.forgedStartsRejected = starts[1] and starts[2] and starts[3] and starts[4] and starts[5]

	local p1 = { call(remotes, "Purchase", "house", 0) }
	local p2 = { call(remotes, "Purchase", {}, nil) }
	local p3 = { call(remotes, "Purchase", "speed", "0") }
	report.forgedPurchasesRejected = p1[1] and p1[2] == false and p2[1] and p2[2] == false and p3[1] and p3[2] == false

	local huge = {}
	for i = 1, 10000 do
		huge[i] = { x = i % 40, z = -(i % 40) }
	end
	local nan = { { x = 0 / 0, z = 0 }, { x = 10, z = -30 }, { x = 30, z = -30 }, { x = 30, z = 0 } }
	local r1 = { call(remotes, "SubmitRoute", huge, {}) }
	local r2 = { call(remotes, "SubmitRoute", nan, {}) }
	local r3 = { call(remotes, "SubmitRoute", "x", 5) }
	report.forgedRoutesRejected = r1[1] and r1[2] == false and r2[1] and r2[2] == false and r3[1] and r3[2] == false

	local e1 = { call(remotes, "SetExhibit", 1.5, "m1") }
	local e2 = { call(remotes, "SetExhibit", "1", nil) }
	local e3 = { call(remotes, "SetExhibit", 1, {}) }
	report.forgedExhibitsRejected = e1[1] and e1[2] == false and e2[1] and e2[2] == false and e3[1] and e3[2] == false

	local req = remotes:FindFirstChild("RequestState") :: RemoteEvent?
	if req then
		for _ = 1, 60 do
			req:FireServer()
		end
	end
	report.stateSpamSent = req ~= nil

	-- Mash: start a real capture on the armed target and fire 30 releases with no delay.
	local target = ReplicatedStorage:FindFirstChild("HC_ProbeTarget") :: ObjectValue?
	local counts = { counted = 0, ignored = 0, other = 0 }
	task.wait(2.5) -- let the CaptureStart rate limit refill after the forged calls
	if target and target.Value then
		local ok, s = call(remotes, "CaptureStart", target.Value)
		report.mashStartOk = ok and type(s) == "table" and s.ok == true
		for _ = 1, 30 do
			local _, r = call(remotes, "CaptureRelease")
			local o = type(r) == "table" and r.outcome or "?"
			if o == "ignored" then
				counts.ignored += 1
			elseif o == "hit" or o == "miss" or o == "success" or o == "fled" then
				counts.counted += 1
			else
				counts.other += 1
			end
		end
	end
	report.mash = counts
	return report
end

function DevProbe.start()
	if not RunService:IsStudio() then
		return
	end
	task.spawn(function()
		local deadline = os.clock() + 20
		while os.clock() < deadline do
			if ReplicatedStorage:GetAttribute("HC_RunProbe") == true then
				local reportEvent = ReplicatedStorage:WaitForChild("HC_ProbeReport", 10) :: RemoteEvent?
				local ok, report = pcall(run)
				if reportEvent then
					reportEvent:FireServer(if ok then report else { error = tostring(report) })
				end
				return
			end
			task.wait(0.25)
		end
	end)
end

return DevProbe
