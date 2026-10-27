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
