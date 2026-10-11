--!strict
-- First-session tutorial as a small state machine. Each step has a `done` check against the
-- player's state. A step is skipped as soon as its check passes, so later progress (e.g. already
-- owning a monster) never traps a returning player on an earlier step.

local Shared = script.Parent.Parent
local Economy = require(Shared.Config.Economy)

local TutorialRules = {}

export type Ctx = {
	nearTrain: boolean,
	inGraveyard: boolean,
	clueCount: number,
	angelClue: boolean,
	seenCount: number,
	captureTried: boolean,
	carrying: boolean,
	owned: number,
	speedLevel: number,
	houseTier: number,
	routeCustom: boolean,
	exhibits: number,
	rides: number,
	bellHint: boolean,
	bellClue: boolean,
	caughtRare: boolean,
}

export type Step = { id: string, text: string, done: (Ctx) -> boolean, alt: ((Ctx) -> string?)? }

local tier1 = Economy.HouseTiers[2]

TutorialRules.Steps = {
	{
		id = "welcome",
		text = "Welcome home! That rickety Ghost Train is yours. Fill it with monsters to make it worth riding.",
		done = function(c)
			return c.nearTrain or c.inGraveyard or c.owned > 0 or c.clueCount > 0
		end,
	},
	{
		id = "toGraveyard",
		text = "Follow the lantern road north to the graveyard gate. Your flashlight is on (F to toggle).",
		done = function(c)
			return c.inGraveyard or c.owned > 0 or c.clueCount > 0
		end,
	},
	{
		id = "landmark",
		text = "Investigate the Weeping Angel statue near the gate. Landmarks reveal clues.",
		done = function(c)
			return c.angelClue or c.clueCount > 0 or c.owned > 0
		end,
	},
	{
		id = "inspect",
		text = "Find a monster and Inspect it to see its rarity and value.",
		done = function(c)
			return c.seenCount > 0 or c.owned > 0
		end,
	},
	{
		id = "capture",
		text = "Press Try Capture, then CATCH when the needle is inside the green zone.",
		done = function(c)
			return c.carrying or c.owned > 0
		end,
	},
	{
		id = "return",
		text = "Run it home before the timer runs out (carrying slows you), then Secure it at your pen.",
		done = function(c)
			return c.owned > 0
		end,
		alt = function(c)
			if not c.carrying then
				return "It got away! Capture another monster and bring it home faster."
			end
			return nil
		end,
	},
	{
		id = "firstUpgrade",
		text = `It's settling in and will soon earn coins. Save {Economy.SpeedLevelCosts[1]} for a Speed upgrade (Mansion menu).`,
		done = function(c)
			return c.speedLevel >= 1 or c.houseTier >= 1
		end,
	},
	{
		id = "tier1",
		text = `Restore your house ({tier1.cost} coins, Mansion menu) to unlock the Track Editor.`,
		done = function(c)
			return c.houseTier >= 1
		end,
	},
	{
		id = "editor",
		text = "Press Edit Track: reshape your route and Confirm it.",
		done = function(c)
			return c.routeCustom
		end,
	},
	{
		id = "exhibit",
		text = "Put a monster on an exhibit near the track (Mansion > Exhibits). Exhibits boost ride payouts.",
		done = function(c)
			return c.exhibits > 0
		end,
	},
	{
		id = "ride",
		text = "Ride your Ghost Train at the station to earn the payout.",
		done = function(c)
			return c.rides > 0
		end,
	},
	{
		id = "bell",
		text = "A distant bell is tolling... Investigate the Bell Tower beyond Mausoleum Hollow.",
		done = function(c)
			return c.bellClue
		end,
	},
	{
		id = "rare",
		text = "Catch the Bell Wraith in the Sealed Crypt (needs 3 landmarks and a Restored house).",
		done = function(c)
			return c.caughtRare
		end,
	},
} :: { Step }

TutorialRules.CompleteText = "Keep hunting: rare variants, the Sealed Crypt and a Grand Mansion await."

function TutorialRules.advance(step: number, ctx: Ctx): number
	local s = math.max(1, step)
	while s <= #TutorialRules.Steps and TutorialRules.Steps[s].done(ctx) do
		s += 1
	end
	return s
end

function TutorialRules.hint(step: number, ctx: Ctx): string
	local def = TutorialRules.Steps[step]
	if not def then
		return TutorialRules.CompleteText
	end
	if def.alt then
		local alt = def.alt(ctx)
		if alt then
			return alt
		end
	end
	return def.text
end

return TutorialRules
