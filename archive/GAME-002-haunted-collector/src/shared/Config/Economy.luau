--!strict
-- Every economy tunable in one place. Draft numbers (GAME-002 design v0.1); tune after playtests.

export type HouseTier = {
	name: string,
	cost: number,
	containment: number, -- max owned monsters
	exhibitSlots: number,
	rideMultiplier: number,
	unlocksEditor: boolean,
	unlocksCrypt: boolean,
	offlineIncome: boolean,
	blurb: string,
}

local Economy = {
	StartingCoins = 0,
	OnboardingReward = 60, -- first secured monster, once
	MaxCoins = 1e9,

	AcclimationSeconds = 30,
	IncomeTickSeconds = 1,

	BaseWalkSpeed = 16,
	SpeedPerLevel = 2,
	SpeedLevelCosts = { 75, 200, 450 }, -- index = level being bought
	-- Carry slowdown by Running Shoes level (index = level + 1): each level shrinks the penalty
	-- (Round 20 Q3; GDD v0.3).
	CarrySpeedMultipliers = { 0.6, 0.7, 0.8, 0.9 },

	-- index 1 = tier 0 (starter). Tier n is HouseTiers[n + 1].
	HouseTiers = {
		{
			name = "Shabby Shack",
			cost = 0,
			containment = 4,
			exhibitSlots = 2,
			rideMultiplier = 1,
			unlocksEditor = false,
			unlocksCrypt = false,
			offlineIncome = false,
			blurb = "A leaky starter house with a rickety ghost train.",
		},
		{
			name = "Restored Manor",
			cost = 250,
			containment = 10,
			exhibitSlots = 3,
			rideMultiplier = 1.5,
			unlocksEditor = true,
			unlocksCrypt = true,
			offlineIncome = false,
			blurb = "Unlocks the Track Editor and the Sealed Crypt key. More containment.",
		},
		{
			name = "Grand Mansion",
			cost = 1500,
			containment = 20,
			exhibitSlots = 4,
			rideMultiplier = 2.5,
			unlocksEditor = true,
			unlocksCrypt = true,
			offlineIncome = true,
			blurb = "A 4th exhibit slot, bigger rides, and capped offline income.",
		},
	} :: { HouseTier },

	OfflineRate = 0.25, -- fraction of live passive income
	OfflineCapSeconds = 2 * 60 * 60,

	-- Ghost train payout
	RideBasePayout = 40,
	RideCooldownSeconds = 20,
	ExhibitRange = 16, -- studs from the nearest track sample
	ExhibitRarityWeight = { Common = 0.25, Uncommon = 0.5, Rare = 1 } :: { [string]: number },
}

return table.freeze(Economy)
