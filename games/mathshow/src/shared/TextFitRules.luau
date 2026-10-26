--!strict
-- Pure text-fit rules for the menu (MENU_TEXT_FIT_AUDIT section E). No Instances, no yields. The Studio gate
-- (tests/studio/TextFit) measures real text and calls these.

local ShapeProfiles = require(script.Parent.ShapeProfiles)

export type Profile = ShapeProfiles.Profile
export type Rect = { x0: number, y0: number, x1: number, y1: number } -- shard-local canvas px
export type Size = { size: number, lines: number }

local TextFitRules = {}

function TextFitRules.profile(key: string): Profile?
	return (ShapeProfiles :: { [string]: Profile })[key]
end

-- True when `rect`, grown by `margin` on every side, lies inside the opaque part of the shard. Every profile band the
-- grown rect touches must reach in far enough on both sides; out-of-bounds fails. For stretched shards the profile is
-- scaled by targetW / w and targetH / h.
function TextFitRules.rectFits(
	profile: Profile,
	rect: Rect,
	margin: number,
	targetW: number?,
	targetH: number?
): boolean
	local tw = targetW or profile.w
	local th = targetH or profile.h
	local sx = tw / profile.w
	local sy = th / profile.h
	local x0, y0, x1, y1 = rect.x0 - margin, rect.y0 - margin, rect.x1 + margin, rect.y1 + margin
	if x1 < x0 or y1 < y0 or x0 < 0 or y0 < 0 or x1 > tw or y1 > th then
		return false
	end
	local bandH = profile.step * sy
	local first = math.floor(y0 / bandH) + 1
	local last = math.ceil(y1 / bandH)
	for i = first, math.min(last, #profile.l) do
		if profile.l[i] * sx > x0 or profile.r[i] * sx < x1 then
			return false
		end
	end
	return last <= #profile.l
end

-- Largest of `sizes` (descending) whose measured single-line width fits `maxWidth`; when none does, the smallest size
-- wraps onto two or more lines. `measure(text, size)` returns the width in px and is injected to keep this pure.
function TextFitRules.fitSize(
	measure: (text: string, size: number) -> number,
	text: string,
	sizes: { number },
	maxWidth: number
): Size
	for _, size in sizes do
		if measure(text, size) <= maxWidth then
			return { size = size, lines = 1 }
		end
	end
	local smallest = sizes[#sizes] or 0
	local width = measure(text, smallest)
	return { size = smallest, lines = math.max(2, math.ceil(width / math.max(maxWidth, 1))) }
end

return TextFitRules
