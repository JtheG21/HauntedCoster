--!strict
-- First-session tutorial as a small state machine. Each step has a `done` check against the
-- player's state. A step is skipped as soon as its check passes, so later progress (e.g. already
-- owning a monster) never traps a returning player on an earlier step.

local Shared = script.Parent.Parent
local Economy = require(Shared.Config.Economy)

local TutorialRules = {}

export type Ctx = {
	nearTrain: boolean,
	viewedCollection: boolean,
	inGraveyard: boolean,
	nearMonster: boolean, -- a wild monster within a few strides
	seenCount: number,
	captureTried: boolean,
	carrying: boolean,
	owned: number,
	speedLevel: number,
	houseTier: number,
	routeCustom: boolean,
	exhibits: number,
	rides: number,
	inCrypt: boolean,
	caughtRare: boolean,
}

export type Step = { id: string, text: string, done: (Ctx) -> boolean, alt: ((Ctx) -> string?)? }

local tier1 = Economy.HouseTiers[2]

TutorialRules.Steps = {
	-- 12 steps after brief §12. Steps 3 and 12 were clue steps; ADR-0007 replaced them in place so a saved
	-- step number still means the same point in the tutorial.
	{
		id = "welcome",
		text = "Welcome home! Walk over to your Ghost Train station. Fill the train with monsters to make it worth riding.",
		done = function(c)
			return c.nearTrain or c.inGraveyard or c.owned > 0
		end,
	},
	{
		id = "toGraveyard",
		text = "Follow the lantern road north to the graveyard gate. Your flashlight is on (F to toggle).",
		done = function(c)
			return c.inGraveyard or c.owned > 0
		end,
	},
	{
		id = "explore",
		text = "Explore past the Weeping Angel. Monsters roam between the graves: walk up to one.",
		done = function(c)
			return c.nearMonster or c.seenCount > 0 or c.owned > 0
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
		id = "meter",
		text = "Press Try Capture. A needle sweeps the meter: press CATCH while it is inside the green zone.",
		done = function(c)
			return c.captureTried or c.carrying or c.owned > 0
		end,
	},
	{
		id = "capture",
		text = "Catch it! A successful catch starts the trip home: a timer starts and you move slower.",
		done = function(c)
			return c.carrying or c.owned > 0
		end,
	},
	{
		id = "return",
		text = "Run it home before the timer runs out, then Secure it at your pen.",
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
		id = "collection",
		text = "It's settling in and will soon earn coins. Open the Mansion menu (M) or the Journal (J) to see your collection and income.",
		done = function(c)
			return c.viewedCollection or c.speedLevel >= 1 or c.houseTier >= 1
		end,
	},
	{
		id = "firstUpgrade",
		text = `Save {Economy.SpeedLevelCosts[1]} coins and buy a Speed upgrade in the Mansion menu.`,
		done = function(c)
			return c.speedLevel >= 1 or c.houseTier >= 1
		end,
	},
	{
		id = "editor",
		text = `Restore your house ({tier1.cost} coins, Mansion menu) to unlock the Track Editor, then press Edit Track and Confirm a route.`,
		done = function(c)
			return c.routeCustom
		end,
	},
	{
		id = "ride",
		text = "Ride your Ghost Train at the station to earn the payout. Monsters on exhibits near the track raise it.",
		done = function(c)
			return c.rides > 0
		end,
	},
	{
		id = "lair",
		text = "Your Restored Manor opened the Sealed Crypt behind the Bell Tower. The rare Bell Wraith haunts it: go in.",
		done = function(c)
			return c.inCrypt or c.caughtRare
		end,
	},
} :: { Step }

TutorialRules.CompleteText = "The rare Bell Wraith haunts the Sealed Crypt. Restore your house to open it."

function TutorialRules.advance(step: number, ctx: Ctx): number
	local s = math.max(1, step)
	while s <= #TutorialRules.Steps and TutorialRules.Steps[s].done(ctx) do
		s += 1
	end
	return s
end

-- After the tutorial: point at the Bell Wraith, naming the house tier if the crypt is still shut.
function TutorialRules.completeHint(ctx: Ctx): string
	if ctx.caughtRare then
		return "You caught the Bell Wraith! Collect its variants and build a better ghost train."
	end
	local tier = Economy.HouseTiers[ctx.houseTier + 1]
	if tier and tier.unlocksCrypt then
		return "The Sealed Crypt is open to you: find the Bell Wraith inside."
	end
	return TutorialRules.CompleteText
end

function TutorialRules.hint(step: number, ctx: Ctx): string
	local def = TutorialRules.Steps[step]
	if not def then
		return TutorialRules.completeHint(ctx)
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
