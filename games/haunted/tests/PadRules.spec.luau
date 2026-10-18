--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PadRules = require(ReplicatedStorage.Shared.Rules.PadRules)

return function(t: TestRunner.T)
	t.test("texture ids: uploaded assets and engine textures only", function()
		t.truthy(PadRules.isTexture("rbxassetid://12402856027"))
		t.truthy(PadRules.isTexture("rbxasset://textures/particles/sparkles_main.dds"))
		for _, bad in
			{
				"",
				"http://example.com/a.png",
				"rbxassetid://",
				"rbxassetid://12a",
				"rbxasset://../secret",
				"rbxasset://textures/../x",
				"https://x/rbxassetid://1",
			}
		do
			t.eq(PadRules.isTexture(bad), false, bad)
		end
		t.eq(PadRules.isTexture(12345), false)
		t.eq(PadRules.isTexture(nil), false)
	end)

	t.test("UI layout: three sizes on both backgrounds, no overlap, inside the frame", function()
		local layout = PadRules.uiLayout()
		t.eq(#layout.cells, #PadRules.UI_SIZES * #PadRules.BACKGROUND_ORDER)
		local seen: { [string]: boolean } = {}
		for _, c in layout.cells do
			seen[`{c.background}{c.size}`] = true
			t.truthy(c.x >= PadRules.GUTTER and c.y >= PadRules.GUTTER)
			t.truthy(c.x + c.size <= layout.width and c.y + c.size <= layout.height, "cell outside frame")
		end
		t.eq(seen.dark48 and seen.dark128 and seen.dark512 and seen.light48 and seen.light128 and seen.light512, true)
		for i = 1, #layout.cells do
			for j = i + 1, #layout.cells do
				local a, b = layout.cells[i], layout.cells[j]
				local overlap = a.x < b.x + b.size and b.x < a.x + a.size and a.y < b.y + b.size and b.y < a.y + a.size
				t.eq(overlap, false, `cells {i} and {j} overlap`)
			end
		end
	end)

	t.test("background colours match the off-Studio matrix", function()
		t.eq(
			PadRules.BACKGROUNDS.dark[1] * 65536 + PadRules.BACKGROUNDS.dark[2] * 256 + PadRules.BACKGROUNDS.dark[3],
			0x1b1b24
		)
		t.eq(
			PadRules.BACKGROUNDS.light[1] * 65536 + PadRules.BACKGROUNDS.light[2] * 256 + PadRules.BACKGROUNDS.light[3],
			0xd9d2c3
		)
	end)

	t.test("VFX camera offsets: three increasing distances", function()
		local offsets = PadRules.vfxCameraOffsets()
		t.eq(#offsets, 3)
		for i = 2, #offsets do
			t.truthy(offsets[i].z > offsets[i - 1].z)
		end
	end)

	t.test("metrics line is stable, sorted and compact", function()
		t.eq(
			PadRules.metricsLine("vfx", { emitters = 2, fps = 59.987, ok = true, name = "x" }),
			"pad=vfx emitters=2 fps=59.99 name=x ok=true"
		)
	end)

	t.test("VFX budget reports every reason it is exceeded", function()
		t.eq((PadRules.vfxWithinBudget(1, 10)), true)
		local ok, why = PadRules.vfxWithinBudget(PadRules.VFX_EMITTER_BUDGET + 1, PadRules.VFX_MAX_RATE + 1)
		t.eq(ok, false)
		t.eq(#why, 2)
	end)
end
