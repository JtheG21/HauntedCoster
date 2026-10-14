--!strict
-- Sound data for the audio pass (TASK-0040). Client-only: Creator Store asset ids, no uploads.
-- PLACEHOLDER SET: every id below is the first measured candidate from games/haunted/audio/shortlist.json,
-- picked so the game can be heard now. jg has not chosen these by ear yet (AC2 is open); swap ids here,
-- keeping `volume`/`looped`, once the Studio sound tour is done. Ids flagged unproven in the task note
-- (amb_woodland 9112764040, monster_call 129823359634605) are deliberately not used.

export type Role = {
	id: number,
	volume: number,
	looped: boolean,
	name: string, -- Creator Store title, for Sound References
	creator: string,
	seconds: number, -- measured TimeLength in Studio (2026-10-12)
}

local SoundBank = {}

SoundBank.placeholder = true

SoundBank.Roles = {
	amb_cemetery = {
		id = 179507208,
		volume = 0.25,
		looped = true,
		name = "Night Ambience",
		creator = "Soybeen",
		seconds = 120.007,
	},
	amb_woodland = {
		id = 136133461808676,
		volume = 0.25,
		looped = true,
		name = "Forest Night Ambience",
		creator = "DistrokidOfficial",
		seconds = 173.259,
	},
	amb_spider_woodland = {
		id = 9112781510,
		volume = 0.25,
		looped = true,
		name = "Forest Ambience 1 (SFX)",
		creator = "ProSoundEffects",
		seconds = 36.011,
	},
	amb_settlement = {
		id = 9113286969,
		volume = 0.25,
		looped = true,
		name = "Barstow Wind Light Blustery Low Howl 2 (SFX)",
		creator = "ProSoundEffects",
		seconds = 37.02,
	},
	amb_hub = {
		id = 9112775175,
		volume = 0.25,
		looped = true,
		name = "Eerie Ambience 1 (SFX)",
		creator = "ProSoundEffects",
		seconds = 56.01,
	},
	capture_start = {
		id = 9125648149,
		volume = 0.5,
		looped = false,
		name = "Magic Zoom Up Sharp Tubular Whoosh Fast Hiss (SFX)",
		creator = "ProSoundEffects",
		seconds = 0.723,
	},
	capture_success = {
		id = 118041409564450,
		volume = 0.6,
		looped = false,
		name = "eksdee12 success",
		creator = "eksdee12",
		seconds = 1.3,
	},
	capture_fled = {
		id = 114989963690677,
		volume = 0.5,
		looped = false,
		name = "Ghost Whoosh",
		creator = "Pickled_Jeans",
		seconds = 1.982,
	},
	retaliation_sting = {
		id = 139966300077528,
		volume = 0.6,
		looped = false,
		name = "louder horror sting",
		creator = "santipansy",
		seconds = 3.789,
	},
	monster_call = {
		id = 87767262209513,
		volume = 0.5,
		looped = false,
		name = "sfx6_0C",
		creator = "BuilderBillbert",
		seconds = 1.174,
	},
	ride_start = {
		id = 120907161220146,
		volume = 0.5,
		looped = false,
		name = "Dead rails train whistle",
		creator = "Kaikoax808",
		seconds = 3.876,
	},
	ride_end = {
		id = 115235942061332,
		volume = 0.4,
		looped = false,
		name = "Train brake screech loop sound sfx",
		creator = "Cursed_Osvvald",
		seconds = 3.58,
	},
	coins = {
		id = 107132538017055,
		volume = 0.5,
		looped = false,
		name = "coins-sound-effect-1-full-pack",
		creator = "Akin_TR",
		seconds = 0.601,
	},
	payout = {
		id = 120891770644830,
		volume = 0.5,
		looped = false,
		name = "cash-register-sound-fx",
		creator = "hotmoldybanana",
		seconds = 1.045,
	},
	rotation_warning = {
		id = 140225556550357,
		volume = 0.5,
		looped = false,
		name = "Bit crushed bell toll",
		creator = "DivergentBin1",
		seconds = 5.684,
	},
	ui_click = {
		id = 15675059323,
		volume = 0.4,
		looped = false,
		name = "Roblox_UI_Bright_Click",
		creator = "Roblox",
		seconds = 0.371,
	},
	toast = {
		id = 17669542615,
		volume = 0.4,
		looped = false,
		name = "Audio/mixkit-dry-pop-up-notification-alert-2356",
		creator = "RedCrafter0",
		seconds = 0.305,
	},
	toast_error = {
		id = 87519554692663,
		volume = 0.4,
		looped = false,
		name = "ui-simple-negative-error",
		creator = "AmbientSorcery",
		seconds = 0.31,
	},
} :: { [string]: Role }

-- Ambience per habitat id (Config/Habitats.luau). Anything else (no active habitat) uses the hub bed.
SoundBank.AmbienceByHabitat = {
	Cemetery = "amb_cemetery",
	Woodland = "amb_woodland",
	SpiderWoodland = "amb_spider_woodland",
	Settlement = "amb_settlement",
} :: { [string]: string }

SoundBank.HubAmbience = "amb_hub"

function SoundBank.ambienceFor(habitatId: string?): string
	if habitatId then
		local role = SoundBank.AmbienceByHabitat[habitatId]
		if role then
			return role
		end
	end
	return SoundBank.HubAmbience
end

-- Which sound a finished capture plays: success gets the chime, a cancel is silent, and every other ending
-- (fled, startled, timeout) the "fled" whoosh.
function SoundBank.captureEndRole(result: any): string?
	if result == "success" then
		return "capture_success"
	elseif result == "cancelled" then
		return nil
	end
	return "capture_fled"
end

function SoundBank.assetUrl(role: string): string?
	local r = SoundBank.Roles[role]
	if r and r.id > 0 then
		return `rbxassetid://{r.id}`
	end
	return nil
end

return SoundBank
