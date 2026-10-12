--!strict
-- First-session tutorial as a small state machine. Each step has a `done` check against the
-- player's state. A step is skipped as soon as its check passes, so later progress (e.g. already
-- owning a monster) never traps a returning player on an earlier step.

local Shared = script.Parent.Parent
local Economy = require(Shared.Config.Economy)
local World = require(Shared.Config.World)

local TutorialRules = {}

export type Ctx = {
	nearTrain: boolean,
	viewedCollection: boolean,
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
	landmarks: number?, -- landmark clues only (the train's bell hint excluded); used by the completion hint
}

export type Step = { id: string, text: string, done: (Ctx) -> boolean, alt: ((Ctx) -> string?)? }

local tier1 = Economy.HouseTiers[2]

TutorialRules.Steps = {
	-- 1-12 follow brief §12 (INBOX-20261011-Haunted-Collector-Brief) one to one.
	{
		id = "welcome",
		text = "Welcome home! Walk over to your Ghost Train station. Fill the train with monsters to make it worth riding.",
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
		id = "bell",
		text = "A distant bell is tolling... Investigate the Bell Tower beyond Mausoleum Hollow.",
		done = function(c)
			return c.bellClue
		end,
	},
} :: { Step }

TutorialRules.CompleteText =
	"The bell points to the Sealed Crypt: investigate 3 landmarks and Restore your house to enter, and find the Bell Wraith."

function TutorialRules.advance(step: number, ctx: Ctx): number
	local s = math.max(1, step)
	while s <= #TutorialRules.Steps and TutorialRules.Steps[s].done(ctx) do
		s += 1
	end
	return s
end

-- After the tutorial: point at the Bell Wraith, naming only what is still missing to enter the Crypt.
function TutorialRules.completeHint(ctx: Ctx): string
	if ctx.caughtRare then
		return "You caught the Bell Wraith! Collect its variants and build a better ghost train."
	end
	local landmarks = ctx.landmarks
	if landmarks == nil then
		return TutorialRules.CompleteText
	end
	local need = World.Graveyard.cryptLandmarksNeeded - landmarks
	local tierOk = Economy.HouseTiers[ctx.houseTier + 1].unlocksCrypt
	if need <= 0 and tierOk then
		return "The Sealed Crypt is open to you: find the Bell Wraith inside."
	end
	local missing = {}
	if need > 0 then
		table.insert(missing, `investigate {need} more landmark{if need == 1 then "" else "s"}`)
	end
	if not tierOk then
		table.insert(missing, "Restore your house")
	end
	return `The bell points to the Sealed Crypt: {table.concat(missing, " and ")} to enter, and find the Bell Wraith.`
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
