--!strict
-- Pure rules for the Studio test pads (TASK-0056): sizes, distances, layouts, texture-id checking and the one-line
-- metrics format. No Roblox services, so Lune tests them; the pads themselves live in tests/scenarios/TestPads.

local PadRules = {}

-- UI pad: the same image at the sizes a button, an icon and a hero image really use, on both backgrounds.
PadRules.UI_SIZES = { 48, 128, 512 }
-- The same dark and light as `evidence.py matrix`, so Studio and off-Studio comparisons agree (0x1b1b24, 0xd9d2c3).
PadRules.BACKGROUNDS = { dark = { 27, 27, 36 }, light = { 217, 210, 195 } }
PadRules.BACKGROUND_ORDER = { "dark", "light" }
PadRules.GUTTER = 16 -- px between cells

-- VFX pad: camera distances in studs (close-up, play distance, far) and what a single effect may cost.
PadRules.VFX_DISTANCES = { 6, 20, 60 }
PadRules.VFX_EMITTER_BUDGET = 3
PadRules.VFX_MAX_RATE = 120 -- particles per second across the pad's emitters

-- Surface pad: one wall plus three reference swatches to judge the texture against.
PadRules.WALL = { width = 24, height = 12, depth = 1 }
PadRules.SWATCHES = { white = { 235, 235, 235 }, grey = { 128, 128, 128 }, black = { 20, 20, 20 } }

-- A texture is either an uploaded asset or one of the engine's own: nothing else may be loaded by a pad.
function PadRules.isTexture(id: any): boolean
	if type(id) ~= "string" then
		return false
	end
	if id:find("..", 1, true) then
		return false -- no path climbing out of the textures folder
	end
	return id:match("^rbxassetid://%d+$") ~= nil or id:match("^rbxasset://textures/[%w_%-%./]+$") ~= nil
end

export type Cell = { size: number, background: string, x: number, y: number }

-- Cells laid out as columns (sizes) by rows (backgrounds), each row as tall as its largest cell.
function PadRules.uiLayout(): { cells: { Cell }, width: number, height: number }
	local cells: { Cell } = {}
	local tallest = PadRules.UI_SIZES[#PadRules.UI_SIZES]
	local y = PadRules.GUTTER
	local width = 0
	for _, background in PadRules.BACKGROUND_ORDER do
		local x = PadRules.GUTTER
		for _, size in PadRules.UI_SIZES do
			table.insert(cells, { size = size, background = background, x = x, y = y })
			x += size + PadRules.GUTTER
		end
		width = math.max(width, x)
		y += tallest + PadRules.GUTTER
	end
	return { cells = cells, width = width, height = y }
end

-- Camera offset (relative to the pad's centre) for each VFX distance: slightly above, looking back at it.
function PadRules.vfxCameraOffsets(): { { distance: number, x: number, y: number, z: number } }
	local out = {}
	for _, d in PadRules.VFX_DISTANCES do
		table.insert(out, { distance = d, x = 0, y = 2 + d * 0.05, z = d })
	end
	return out
end

-- One line, stable key order, so runs can be diffed and pasted into a task note.
function PadRules.metricsLine(pad: string, fields: { [string]: any }): string
	local keys = {}
	for k in fields do
		table.insert(keys, k)
	end
	table.sort(keys)
	local parts = { "pad=" .. pad }
	for _, k in keys do
		local v = fields[k]
		local text = if type(v) == "number"
			then (if v == math.floor(v) then tostring(v) else string.format("%.2f", v))
			else tostring(v)
		table.insert(parts, k .. "=" .. text)
	end
	return table.concat(parts, " ")
end

-- Whether a measured effect is inside the pad's budget; returns the reasons it is not.
function PadRules.vfxWithinBudget(emitters: number, ratePerSecond: number): (boolean, { string })
	local why = {}
	if emitters > PadRules.VFX_EMITTER_BUDGET then
		table.insert(why, `{emitters} emitters, budget {PadRules.VFX_EMITTER_BUDGET}`)
	end
	if ratePerSecond > PadRules.VFX_MAX_RATE then
		table.insert(why, `{ratePerSecond} particles/s, budget {PadRules.VFX_MAX_RATE}`)
	end
	return #why == 0, why
end

return PadRules
