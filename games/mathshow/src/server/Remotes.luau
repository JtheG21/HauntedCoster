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

local function remoteFunction(name: string): RemoteFunction
	local existing = parent:FindFirstChild(name)
	if existing then
		if not existing:IsA("RemoteFunction") then
			error(`Remotes: {name} is a {existing.ClassName}, expected RemoteFunction`)
		end
		return existing
	end
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent
	return remote
end

return table.freeze({
	RoundState = event(Net.RoundState),
	SubmitAnswer = event(Net.SubmitAnswer),
	AnswerResult = event(Net.AnswerResult),
	QueueJoin = event(Net.QueueJoin),
	QueueCancel = event(Net.QueueCancel),
	QueueKeepWaiting = event(Net.QueueKeepWaiting),
	QueueState = event(Net.QueueState),
	VsAnswer = event(Net.VsAnswer),
	VsState = event(Net.VsState),
	VsResult = event(Net.VsResult),
	RematchRequest = event(Net.RematchRequest),
	BlitzStart = event(Net.BlitzStart),
	BlitzAnswer = event(Net.BlitzAnswer),
	BlitzState = event(Net.BlitzState),
	AnswerAck = event(Net.AnswerAck),
	BlitzResult = event(Net.BlitzResult),
	SkillStart = event(Net.SkillStart),
	SkillAnswer = event(Net.SkillAnswer),
	SkillState = event(Net.SkillState),
	SkillResult = event(Net.SkillResult),
	JoinShow = event(Net.JoinShow),
	ShowState = event(Net.ShowState),
	MenuRequest = remoteFunction(Net.MenuRequest),
	SettingsSave = event(Net.SettingsSave),
})
