--!strict
-- Creates every remote declared in Shared.Net and provides a per-player token-bucket rate limiter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Remotes = {}

local folder: Folder? = nil
local events: { [string]: RemoteEvent } = {}
local functions: { [string]: RemoteFunction } = {}

local function ensure()
	if folder then
		return
	end
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	local root: Folder = if existing and existing:IsA("Folder") then existing else Instance.new("Folder")
	root.Name = "Remotes"
	folder = root
	for _, name in Net.Events do
		local found = root:FindFirstChild(name)
		local e: RemoteEvent
		if found and found:IsA("RemoteEvent") then
			e = found
		else
			e = Instance.new("RemoteEvent")
			e.Name = name
			e.Parent = root
		end
		events[name] = e
	end
	for _, name in Net.Functions do
		local found = root:FindFirstChild(name)
		local fn: RemoteFunction
		if found and found:IsA("RemoteFunction") then
			fn = found
		else
			fn = Instance.new("RemoteFunction")
			fn.Name = name
			fn.Parent = root
		end
		functions[name] = fn
	end
	root.Parent = ReplicatedStorage
end

function Remotes.event(name: string): RemoteEvent
	ensure()
	local e = events[name]
	assert(e, `unknown remote event {name}`)
	return e
end

function Remotes.func(name: string): RemoteFunction
	ensure()
	local f = functions[name]
	assert(f, `unknown remote function {name}`)
	return f
end

-- Token bucket: `rate` tokens per second, up to `burst`. Returns false when the call should be dropped.
type Bucket = { tokens: number, at: number }
local buckets: { [Player]: { [string]: Bucket } } = {}

function Remotes.allow(player: Player, key: string, rate: number, burst: number): boolean
	local now = os.clock()
	local mine = buckets[player]
	if not mine then
		mine = {}
		buckets[player] = mine
	end
	local b = mine[key]
	if not b then
		b = { tokens = burst, at = now }
		mine[key] = b
	end
	b.tokens = math.min(burst, b.tokens + (now - b.at) * rate)
	b.at = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

Players.PlayerRemoving:Connect(function(player)
	buckets[player] = nil
end)

return Remotes
