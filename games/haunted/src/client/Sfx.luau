--!strict
-- Client-only sound (TASK-0040). One SoundGroup holds every game sound; muting zeroes the group, so ambience
-- keeps its place. Every entry point fails silent: a missing role, a bad id or an asset Roblox removed
-- never raises, it just stays quiet.

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundBank = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("SoundBank"))

local Sfx = {}

local group: SoundGroup? = nil
local muted = false
local ambient: Sound? = nil
local ambientRole: string? = nil
local lastPlayed: { [string]: number } = {}

local MIN_GAP = 0.08 -- seconds; stops a burst of one role stacking into noise

local function ensureGroup(): SoundGroup
	if group and group.Parent then
		return group
	end
	local g = Instance.new("SoundGroup")
	g.Name = "HauntedSfx"
	g.Volume = if muted then 0 else 1
	g.Parent = SoundService
	group = g
	return g
end

local function make(role: string, looped: boolean): Sound?
	local def = SoundBank.Roles[role]
	local url = SoundBank.assetUrl(role)
	if not def or not url then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = role
	s.SoundId = url
	s.Volume = def.volume
	s.Looped = looped
	s.SoundGroup = ensureGroup()
	s.Parent = SoundService
	return s
end

function Sfx.isMuted(): boolean
	return muted
end

function Sfx.setMuted(value: boolean)
	muted = value
	if group and group.Parent then
		group.Volume = if value then 0 else 1
	end
end

function Sfx.toggleMuted(): boolean
	Sfx.setMuted(not muted)
	return muted
end

-- One-shot. Safe to call with any role name; unknown roles do nothing.
function Sfx.play(role: string)
	local now = os.clock()
	local last = lastPlayed[role]
	if last and now - last < MIN_GAP then
		return
	end
	lastPlayed[role] = now
	local ok = pcall(function()
		local s = make(role, false)
		if not s then
			return
		end
		s.Ended:Once(function()
			s:Destroy()
		end)
		s:Play()
		-- If the asset never loads, Ended never fires; drop it after a generous bound.
		task.delay(15, function()
			if s.Parent then
				s:Destroy()
			end
		end)
	end)
	if not ok then
		return
	end
end

-- The single looping ambience bed; switching to the role already playing is a no-op.
function Sfx.setAmbience(role: string?)
	if role == ambientRole then
		return
	end
	ambientRole = role
	pcall(function()
		if ambient then
			ambient:Destroy()
			ambient = nil
		end
		if role then
			local s = make(role, true)
			if s then
				s:Play()
				ambient = s
			end
		end
	end)
end

return Sfx
