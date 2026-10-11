--!strict
-- Latest server snapshot for this player, with a change signal. Read-only on the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = {}

State.snap = nil :: { [string]: any }?

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

local started = false

function State.start()
	if started then
		return
	end
	started = true
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local stateEvent = remotes:WaitForChild("State") :: RemoteEvent
	stateEvent.OnClientEvent:Connect(function(snap)
		if type(snap) == "table" then
			State.snap = snap
			changed:Fire(snap)
		end
	end)
	local request = remotes:WaitForChild("RequestState") :: RemoteEvent
	request:FireServer()
end

function State.remote(name: string): Instance
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name)
end

function State.invoke(name: string, ...: any): ...any
	local f = State.remote(name) :: RemoteFunction
	local results = table.pack(pcall(f.InvokeServer, f, ...))
	if not results[1] then
		warn(`[Client] {name} failed: {results[2]}`)
		return nil
	end
	return table.unpack(results, 2, results.n)
end

return State
