--!strict
-- Quests (TASK-0151): the client side of daily quests and player level. Receives QuestState from QuestService (TASK-0150),
-- keeps the newest one (revision is monotonic: an older push never regresses the screen), turns it into the QUESTS screen
-- and level-card models, and shows the quest-complete / claimed / bonus / level-up toasts. Sends only QuestRequest (no
-- payload) and QuestClaim { day, slot, boardRevision, generation }, echoing the identity the server sent; the server
-- decides every award. Toasts wait while this player is answering a gameshow question and show at its Reveal. Fails inert:
-- a malformed push is warned and ignored.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LevelRewards = require(Shared:WaitForChild("LevelRewards"))
local MenuCopy = require(Shared:WaitForChild("MenuCopy"))
local Net = require(Shared:WaitForChild("Net"))
local QuestConfig = require(Shared:WaitForChild("QuestConfig"))
local XpConfig = require(Shared:WaitForChild("XpConfig"))

local MenuTheme = require(script.Parent.MenuTheme)
local View = require(script.Parent.View)

local Quests = {}

local CONNECT_TIMEOUT = 10
local SLOTS = QuestConfig.SlotCount

type Slot = { id: string, generation: number, progress: number, claimed: boolean }
type State = {
	revision: number,
	result: string,
	persistence: string,
	day: number?,
	boardRevision: number?,
	slots: { Slot },
	bonusGranted: boolean,
	level: number,
	xpIntoLevel: number,
	nextLevelXp: number,
	pendingClaim: number?,
}

local started = false
local current: State? = nil
local listeners: { () -> () } = {}
local toastView: View.View? = nil
local queue: { { text: string, kind: string } } = {}
local showing = false
local holding = false -- answering a gameshow question: toasts wait for its Reveal
local participant = false
local lastRequest = -math.huge
local lastAction = -math.huge -- the player pressed CLAIM or RETRY: a "rate" / "stale" reply gets a toast

local function fill(template: string, values: { [string]: string | number }): string
	return (
		string.gsub(template, "{(%w+)}", function(key: string)
			local v = values[key]
			return if v ~= nil then tostring(v) else "{" .. key .. "}"
		end)
	)
end

local function isInt(v: any): boolean
	return typeof(v) == "number" and v == v and v == math.floor(v) and math.abs(v) < 2 ^ 53
end

-- Type checks only; the server is the authority on every value. Returns nil for anything malformed.
local function parse(p: any): State?
	if typeof(p) ~= "table" then
		return nil
	end
	if
		not isInt(p.revision)
		or typeof(p.result) ~= "string"
		or typeof(p.persistence) ~= "string"
		or typeof(p.slots) ~= "table"
		or not isInt(p.level)
		or not isInt(p.xpIntoLevel)
		or not isInt(p.nextLevelXp)
	then
		return nil
	end
	local slots: { Slot } = {}
	for i, s in p.slots do
		if
			typeof(i) ~= "number"
			or typeof(s) ~= "table"
			or typeof(s.id) ~= "string"
			or not isInt(s.generation)
			or not isInt(s.progress)
			or typeof(s.claimed) ~= "boolean"
		then
			return nil
		end
		slots[i] = { id = s.id, generation = s.generation, progress = s.progress, claimed = s.claimed }
	end
	return {
		revision = p.revision,
		result = p.result,
		persistence = p.persistence,
		day = if isInt(p.day) then p.day else nil,
		boardRevision = if isInt(p.boardRevision) then p.boardRevision else nil,
		slots = slots,
		bonusGranted = p.bonusGranted == true,
		level = p.level,
		xpIntoLevel = p.xpIntoLevel,
		nextLevelXp = p.nextLevelXp,
		pendingClaim = if isInt(p.pendingClaim) then p.pendingClaim else nil,
	}
end

local function questOf(slot: Slot?): QuestConfig.Quest?
	return if slot then (QuestConfig.Catalog :: { [string]: QuestConfig.Quest })[slot.id] else nil
end

local function ready(s: State?): boolean
	return s ~= nil and (s.persistence == "saved" or s.persistence == "memory") and #s.slots == SLOTS
end

local function titleAt(level: number): string?
	local rewards = LevelRewards.rewardsFor(level)
	return if rewards and rewards.title then rewards.title.name else nil
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Toasts

local function buildToast()
	local ok, err = pcall(function()
		local function noop() end
		local handlers: View.Handlers = {
			go = noop,
			back = noop,
			locked = function(_what: string) end,
			join = noop,
			retry = noop,
			skillSelect = function(_index: number) end,
			skillLock = function(_value: number) end,
			blitzLock = function(_value: number) end,
			vsLock = function(_value: number) end,
			vsKeepWaiting = noop,
			vsRematch = noop,
			vsRetry = noop,
			setting = function(_key: string, _value: number | boolean) end,
		}
		toastView = View.build(Players.LocalPlayer:WaitForChild("PlayerGui"), handlers, {
			overlay = true,
			name = "MathShowQuestToast",
			displayOrder = 11, -- above the menu (10), so it shows whether or not the menu is open
		})
	end)
	if not ok then
		warn(`[MathShow] Quest toast failed to build: {err}`)
	end
end

local function pump()
	if showing or holding then
		return
	end
	local nextToast = table.remove(queue, 1)
	local v = toastView
	if not nextToast or not v then
		return
	end
	showing = true
	local ok, err = pcall(function()
		v.notify(nextToast.text, nextToast.kind, MenuTheme.QuestToastSeconds)
	end)
	if not ok then
		warn(`[MathShow] Quest toast failed: {err}`)
	end
	task.delay(MenuTheme.QuestToastSeconds + MenuTheme.QuestToastGap, function()
		showing = false
		pump()
	end)
end

local function enqueue(text: string, kind: string)
	if #queue >= MenuTheme.QuestToastQueueMax then
		table.remove(queue, 1) -- a burst keeps the newest
	end
	table.insert(queue, { text = text, kind = kind })
	pump()
end

-- What changed between two confirmed states that the player should hear about. Same day and board only: a new day or a
-- rebuilt board is not a completion.
local function announce(old: State, new: State)
	if ready(old) and ready(new) and old.day == new.day and old.boardRevision == new.boardRevision then
		for i = 1, SLOTS do
			local a, b = old.slots[i], new.slots[i]
			local quest = questOf(b)
			if quest and a.id == b.id and a.generation == b.generation then
				if not b.claimed and a.progress < quest.target and b.progress >= quest.target then
					enqueue(fill(MenuCopy.Quests.ToastQuest, { xp = quest.xp }), "green")
				elseif not a.claimed and b.claimed then
					enqueue(fill(MenuCopy.Quests.ToastClaimed, { xp = quest.xp }), "green")
				end
			end
		end
		if not old.bonusGranted and new.bonusGranted then
			enqueue(fill(MenuCopy.Quests.ToastBonus, { xp = XpConfig.AllThreeBonus }), "green")
		end
	end
	if new.level > old.level then
		local title = titleAt(new.level)
		if title and title ~= titleAt(old.level) then
			enqueue(fill(MenuCopy.Quests.ToastTitle, { level = new.level, title = string.upper(title) }), "green")
		else
			enqueue(fill(MenuCopy.Quests.ToastLevel, { level = new.level }), "green")
		end
	end
	local recent = os.clock() - lastAction < MenuTheme.QuestActionWindow
	if recent and new.result == "rate" then
		enqueue(MenuCopy.Quests.Busy, "silver")
	elseif recent and new.result == "stale" then
		enqueue(MenuCopy.Quests.Stale, "silver")
	end
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Remotes

local function remoteNamed(name: string): RemoteEvent?
	local folder = ReplicatedStorage:WaitForChild("Remotes", CONNECT_TIMEOUT)
	local remote = if folder then folder:WaitForChild(name, CONNECT_TIMEOUT) else nil
	return if remote and remote:IsA("RemoteEvent") then remote else nil
end

local function notify()
	for _, fn in listeners do
		local ok, err = pcall(function()
			fn()
		end)
		if not ok then
			warn(`[MathShow] Quests listener failed: {err}`)
		end
	end
end

local function onState(p: any)
	local s = parse(p)
	if s == nil then
		warn("[MathShow] Quests ignored a malformed QuestState")
		return
	end
	local old = current
	if old and s.revision <= old.revision then
		return -- an older push: never regress
	end
	current = s
	if old then
		announce(old, s)
	end
	notify()
end

-- Asks for this player's state (the server answers with QuestState). Throttled here as well as on the server.
function Quests.request()
	local now = os.clock()
	if now - lastRequest < MenuTheme.QuestRequestSeconds then
		return
	end
	lastRequest = now
	task.spawn(function()
		local remote = remoteNamed(Net.QuestRequest)
		if remote then
			remote:FireServer()
		else
			warn("[MathShow] Quests: QuestRequest remote not found")
		end
	end)
end

function Quests.retry()
	lastAction = os.clock()
	lastRequest = -math.huge
	Quests.request()
end

-- CLAIM on a card. Sends only what the server sent for that slot; nothing for a slot that is not complete and unclaimed.
function Quests.claim(slot: number)
	local s = current
	if not ready(s) or s == nil or s.day == nil or s.boardRevision == nil or s.pendingClaim ~= nil then
		return
	end
	local entry = s.slots[slot]
	local quest = questOf(entry)
	if not entry or not quest or entry.claimed or entry.progress < quest.target then
		return
	end
	lastAction = os.clock()
	local payload = { day = s.day, slot = slot, boardRevision = s.boardRevision, generation = entry.generation }
	task.spawn(function()
		local remote = remoteNamed(Net.QuestClaim)
		if remote then
			remote:FireServer(payload)
		else
			warn("[MathShow] Quests: QuestClaim remote not found")
		end
	end)
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Models

-- The level card on the main menu, or nil before the first QuestState.
function Quests.level(): (number?, number?, number?)
	local s = current
	if s == nil then
		return nil, nil, nil
	end
	return s.level, s.xpIntoLevel, s.nextLevelXp
end

function Quests.model(): View.QuestsModel
	local s = current
	if s == nil or s.persistence == "loading" then
		return { status = "loading", cards = {}, bonusGranted = false, bonusXp = XpConfig.AllThreeBonus }
	end
	if not ready(s) then
		return { status = "unavailable", cards = {}, bonusGranted = false, bonusXp = XpConfig.AllThreeBonus }
	end
	local cards: { View.QuestCardModel } = {}
	for i = 1, SLOTS do
		local slot = s.slots[i]
		local quest = questOf(slot)
		if quest == nil then
			-- An id this client does not know (a newer catalog): the server will not take a claim we cannot show.
			return { status = "unavailable", cards = {}, bonusGranted = false, bonusXp = XpConfig.AllThreeBonus }
		end
		local kind = (MenuCopy.Quests.Kind :: any)[quest.kind]
		local template = if quest.target == 1 then kind.One else kind.Many
		local done = slot.progress >= quest.target
		cards[i] = {
			description = fill(template, { n = quest.target }),
			difficulty = quest.difficulty,
			xp = quest.xp,
			progress = math.min(slot.progress, quest.target),
			target = quest.target,
			status = if slot.claimed
				then "claimed"
				elseif s.pendingClaim == i then "claiming"
				elseif done then "claim"
				else "progress",
		}
	end
	return { status = "ready", cards = cards, bonusGranted = s.bonusGranted, bonusXp = XpConfig.AllThreeBonus }
end

-- fn runs after every accepted QuestState (the menu re-renders the screen it shows).
function Quests.subscribe(fn: () -> ())
	table.insert(listeners, fn)
end

function Quests.start()
	if started then
		return
	end
	started = true
	buildToast()
	task.spawn(function()
		local remote = remoteNamed(Net.QuestState)
		if not remote then
			warn("[MathShow] Quests: QuestState remote not found; quests and level stay hidden")
			return
		end
		remote.OnClientEvent:Connect(function(p: any)
			local ok, err = pcall(function()
				onState(p)
			end)
			if not ok then
				warn(`[MathShow] Quests QuestState failed: {err}`)
			end
		end)
		Quests.request() -- the server's first push may have gone out before this listener existed
	end)
	-- Toasts wait while this player answers a gameshow question (ShowState.participant and RoundState Question).
	task.spawn(function()
		local show = remoteNamed(Net.ShowState)
		if show then
			show.OnClientEvent:Connect(function(p: any)
				if typeof(p) == "table" and typeof(p.participant) == "boolean" then
					participant = p.participant
					if not participant and holding then
						holding = false
						pump()
					end
				end
			end)
		end
	end)
	task.spawn(function()
		local round = remoteNamed(Net.RoundState)
		if round then
			round.OnClientEvent:Connect(function(p: any)
				if typeof(p) ~= "table" or typeof(p.phase) ~= "string" then
					return
				end
				local wasHolding = holding
				holding = participant and p.phase == "Question"
				if wasHolding and not holding then
					pump()
				end
			end)
		end
	end)
end

return Quests
