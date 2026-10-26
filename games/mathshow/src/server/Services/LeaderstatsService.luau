--!strict
-- LeaderstatsService: the per-player `Score` leaderstat (TASK-0094). It is written only from RoundService at
-- Reveal and match reset, never on submit, so the replicated IntValue cannot leak who has answered. In-memory
-- only: nothing is saved. Cosmetic: callers pcall it so a fault here can never stop the match loop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local StandingsRules = require(ReplicatedStorage.Shared.StandingsRules)

local LeaderstatsService = {}

local started = false

local function scoreValue(player: Player): IntValue?
	local folder = player:FindFirstChild("leaderstats")
	local value = if folder then folder:FindFirstChild("Score") else nil
	return if value and value:IsA("IntValue") then value else nil
end

local function setup(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local score = Instance.new("IntValue")
	score.Name = "Score"
	score.Value = 0
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	score.Parent = folder
	folder.Parent = player -- parent last: the client only ever sees a complete leaderstats folder
end

-- Sets each current player's Score to their entry's points, else 0 (non-participants, late joiners).
function LeaderstatsService.publish(scores: { Net.ScoreEntry }): ()
	local byUser: { [number]: number } = {}
	for _, entry in scores do
		byUser[entry.userId] = StandingsRules.cleanPoints(entry.points)
	end
	for _, player in Players:GetPlayers() do
		local value = scoreValue(player)
		if value then
			value.Value = byUser[player.UserId] or 0
		end
	end
end

function LeaderstatsService.reset(): ()
	for _, player in Players:GetPlayers() do
		local value = scoreValue(player)
		if value then
			value.Value = 0
		end
	end
end

function LeaderstatsService.start(): ()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		setup(player)
	end
end

return LeaderstatsService
