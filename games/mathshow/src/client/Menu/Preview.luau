--!strict
-- Dev-only Preview harness (TASK-0098). Renders any built menu state by id with fixture data, and the stress fixtures
-- from MENU_TEXT_FIT_AUDIT.md. Studio only: every entry point returns immediately in a live server.
-- From the Studio command bar (Play, client): require(game.Players.LocalPlayer.PlayerScripts.Client.Menu.Preview).show("01-main")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local MenuConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MenuConfig"))

local Fx = require(script.Parent.Parent.Hud.Fx)
local View = require(script.Parent.View)

local Preview = {}

export type State = { id: string, screen: string, model: View.Model, fixtures: { [string]: View.Model }? }

local ALL_OPEN = { blitz = true, vs = true, group = true }
local UNSETTLED = { music = 0, sfx = 10, reducedMotion = true, colorBlind = false, haptics = false }

local function player(name: string, rank: number?, failed: boolean?): View.Player
	return { name = name, userId = nil, rank = rank, failed = failed }
end

-- Stress fixtures for the main menu's player card (audit E4 items that exist in this scope).
Preview.PlayerFixtures = {
	standard = player("JtheG21", 4),
	wide20 = player(string.rep("W", 20), 9),
	official = player("SirCountsALot_Official", 8),
	demon2 = player("DemonSlayer", 7),
	unranked = player("NewContestant", nil),
	unavailable = player("OfflineRival", nil, true),
}

Preview.States = {
	{ id = "01-main", screen = "main", model = { player = Preview.PlayerFixtures.standard } },
	{ id = "02a-modes", screen = "modes", model = { flags = ALL_OPEN } },
	{ id = "02b-modes-locked", screen = "modes", model = { flags = MenuConfig.ModeEnabled } },
	{ id = "03a-confirm-blitz", screen = "confirm_blitz", model = { flags = ALL_OPEN, best = "6/10" } },
	{ id = "03b-confirm-vs", screen = "confirm_vs", model = { flags = ALL_OPEN } },
	{ id = "03b-confirm-vs-waiting", screen = "confirm_vs", model = { flags = ALL_OPEN, waiting = true } },
	{ id = "03c-confirm-group", screen = "confirm_group", model = { flags = ALL_OPEN } },
	{ id = "17a-settings", screen = "settings", model = { settings = MenuConfig.SettingsDefaults } },
	{ id = "17b-settings-alt", screen = "settings", model = { settings = UNSETTLED } },
	{ id = "10-group-watching", screen = "watching", model = {} },
	{
		id = "11a-practice",
		screen = "practice",
		model = { practice = { rank = 3, lastTestRank = 3, retryRemaining = 0 } },
	},
	{
		id = "11b-practice-cooldown",
		screen = "practice",
		model = { practice = { rank = 7, lastTestRank = 6, retryRemaining = 272 } },
	},
	{ id = "11c-practice-unranked", screen = "practice", model = { practice = { retryRemaining = 0 } } },
	{ id = "19a-rank-unavailable", screen = "practice", model = { practice = { failed = true } } },
	{ id = "12a-skill-intro", screen = "skillintro", model = { practice = { rank = 3, lastTestRank = 3 } } },
	{ id = "12b-skill-intro-first", screen = "skillintro", model = { practice = {} } },
	{ id = "16a-rank-ladder", screen = "ladder", model = { practice = { rank = 3 } } },
	{ id = "16b-rank-ladder-demon", screen = "ladder", model = { practice = { rank = 8 } } },
	{ id = "16c-rank-ladder-unranked", screen = "ladder", model = { practice = {} } },
	{
		id = "13a-skill-typed",
		screen = "skill",
		model = {
			skill = {
				kind = "integer",
				rank = 3,
				problem = "Hypotenuse: legs 12, 16 = ?",
				misses = 0,
				total = 20,
				phase = "question",
				locked = false,
			},
		},
	},
	{
		id = "13b-skill-typed-locked",
		screen = "skill",
		model = {
			skill = {
				kind = "integer",
				rank = 1,
				problem = "8 + 2 \u{00D7} 3 = ?",
				misses = 1,
				total = 20,
				phase = "question",
				locked = true,
			},
		},
	},
	{
		id = "13c-skill-typed-reveal",
		screen = "skill",
		model = {
			skill = {
				kind = "integer",
				rank = 2,
				problem = "9x + 16 = 106, x = ?",
				misses = 2,
				total = 20,
				phase = "reveal",
				locked = true,
				correct = false,
				correctValue = 10,
			},
		},
	},
	{
		id = "14a-skill-choice",
		screen = "skill",
		model = {
			skill = {
				kind = "choice",
				rank = 7,
				problem = "d/dx (x\u{00B3} + 2x) at x = 2 = ?",
				choices = { "14", "99999999999999", "-12", "1234567" },
				misses = 0,
				total = 25,
				phase = "question",
				selected = 2,
				locked = false,
			},
		},
	},
	{
		id = "14b-skill-choice-locked",
		screen = "skill",
		model = {
			skill = {
				kind = "choice",
				rank = 9,
				problem = "d/dx (x\u{00B2}y) at (6, 6) = ?",
				choices = { "72", "36", "12", "-6" },
				misses = 1,
				total = 25,
				phase = "question",
				selected = 1,
				locked = true,
			},
		},
	},
	{
		id = "14c-skill-choice-reveal-wrong",
		screen = "skill",
		model = {
			skill = {
				kind = "choice",
				rank = 6,
				problem = "d/dx (x\u{00B3}) at x = 6 = ?",
				choices = { "108", "18", "216", "36" },
				misses = 1,
				total = 25,
				phase = "reveal",
				locked = true,
				chosen = 2,
				correct = false,
				correctIndex = 1,
			},
		},
	},
	{
		id = "14d-skill-choice-reveal-correct",
		screen = "skill",
		model = {
			skill = {
				kind = "choice",
				rank = 5,
				problem = "log2(128) = ?",
				choices = { "6", "7", "8", "9" },
				misses = 0,
				total = 25,
				phase = "reveal",
				locked = true,
				chosen = 2,
				correct = true,
				correctIndex = 2,
			},
		},
	},
	{
		id = "15a-result-up",
		screen = "skillresult",
		model = { result = { kind = "up", best = 6, cleared = 6, previousBest = 5, retryRemaining = 300 } },
	},
	{
		id = "15b-result-held",
		screen = "skillresult",
		model = { result = { kind = "held", best = 7, cleared = 5, previousBest = 7, retryRemaining = 272 } },
	},
	{
		id = "15c-result-first",
		screen = "skillresult",
		model = { result = { kind = "first", best = 3, cleared = 3, retryRemaining = 300 } },
	},
	{
		id = "15d-result-up-demon",
		screen = "skillresult",
		model = { result = { kind = "up", best = 8, cleared = 8, previousBest = 7, retryRemaining = 299 } },
	},
	{ id = "18-how-to-play", screen = "howto", model = {} },
	{
		id = "20-coming-soon",
		screen = "main",
		model = { player = Preview.PlayerFixtures.standard, toast = "COMING SOON", holdToast = true },
	},
} :: { State }

local active: View.View? = nil

local function noop() end

local function allowed(): boolean
	return RunService:IsStudio()
end

function Preview.find(id: string): State?
	for _, state in Preview.States do
		if state.id == id then
			return state
		end
	end
	return nil
end

-- Builds a fresh preview ScreenGui (handlers do nothing) and renders `id`. `fixture` names a PlayerFixtures entry for
-- the main menu. Motion is snapped (reduced) so layout is final immediately.
function Preview.show(id: string, fixture: string?): View.View?
	if not allowed() then
		return nil
	end
	local state = Preview.find(id)
	if not state then
		warn(`[MathShow] Preview: no state {id}`)
		return nil
	end
	Preview.clear()
	Fx.setReducedMotion(true)
	local handlers: View.Handlers = {
		go = noop,
		back = noop,
		locked = function(_what: string) end,
		join = noop,
		retry = noop,
		skillSelect = function(_index: number) end,
		skillLock = function(_value: number) end,
		setting = function(_key: string, _value: number | boolean) end,
	}
	local view = View.build(Players.LocalPlayer:WaitForChild("PlayerGui"), handlers)
	view.gui.Name = "MathShowMenuPreview"
	local model = table.clone(state.model)
	if fixture and (Preview.PlayerFixtures :: { [string]: View.Player })[fixture] then
		model.player = (Preview.PlayerFixtures :: { [string]: View.Player })[fixture]
	end
	view.render(state.screen, model)
	active = view
	return view
end

function Preview.clear()
	if active then
		active.destroy()
		active = nil
	end
end

return Preview
