--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundBank = require(ReplicatedStorage.Shared.Config.SoundBank)
local Habitats = require(ReplicatedStorage.Shared.Config.Habitats)

local REQUIRED = {
	"amb_cemetery",
	"amb_woodland",
	"amb_spider_woodland",
	"amb_settlement",
	"amb_hub",
	"capture_start",
	"capture_success",
	"capture_fled",
	"retaliation_sting",
	"monster_call",
	"ride_start",
	"ride_end",
	"coins",
	"payout",
	"rotation_warning",
	"ui_click",
	"toast",
	"toast_error",
}

return function(t: TestRunner.T)
	t.test("every spec role is in the bank with a usable id and volume", function()
		for _, name in REQUIRED do
			local r = SoundBank.Roles[name]
			t.truthy(r, `missing role {name}`)
			t.truthy(r.id > 0, `{name} id`)
			t.truthy(r.volume > 0 and r.volume <= 1, `{name} volume`)
			t.truthy(r.seconds > 0, `{name} measured length`)
			t.eq(SoundBank.assetUrl(name), `rbxassetid://{r.id}`, `{name} url`)
		end
	end)

	t.test("only ambience roles loop", function()
		for name, r in SoundBank.Roles do
			t.eq(r.looped, string.sub(name, 1, 4) == "amb_", `{name} looped`)
		end
	end)

	t.test("ambience follows the active habitat and falls back to the hub bed", function()
		for _, h in Habitats.List do
			local role = SoundBank.ambienceFor(h.id)
			t.truthy(SoundBank.Roles[role], `habitat {h.id} has an ambience role`)
		end
		t.eq(SoundBank.ambienceFor(nil), "amb_hub")
		t.eq(SoundBank.ambienceFor("NotAHabitat"), "amb_hub")
		t.eq(SoundBank.ambienceFor("Cemetery"), "amb_cemetery")
	end)

	t.test("capture endings map to chime, whoosh or silence", function()
		t.eq(SoundBank.captureEndRole("success"), "capture_success")
		t.eq(SoundBank.captureEndRole("fled"), "capture_fled")
		t.eq(SoundBank.captureEndRole("startled"), "capture_fled")
		t.eq(SoundBank.captureEndRole("timeout"), "capture_fled")
		t.eq(SoundBank.captureEndRole("cancelled"), nil)
	end)

	t.test("unknown roles have no asset url", function()
		t.eq(SoundBank.assetUrl("nope"), nil)
	end)
end
