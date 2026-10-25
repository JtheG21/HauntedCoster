--!strict
-- Creates (or reuses) ReplicatedStorage.Remotes and the MathShow RemoteEvents named in shared/Net. Only the
-- server requires this; a second require returns the same frozen table.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local function folder(): Instance
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		if not existing:IsA("Folder") then
			error(`Remotes: ReplicatedStorage.Remotes is a {existing.ClassName}, expected Folder`)
		end
		return existing
	end
	local created = Instance.new("Folder")
	created.Name = "Remotes"
	created.Parent = ReplicatedStorage
	return created
end

local parent = folder()

local function event(name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing then
		if not existing:IsA("RemoteEvent") then
			error(`Remotes: {name} is a {existing.ClassName}, expected RemoteEvent`)
		end
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

return table.freeze({
	RoundState = event(Net.RoundState),
	SubmitAnswer = event(Net.SubmitAnswer),
	AnswerResult = event(Net.AnswerResult),
})
