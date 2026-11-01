--!strict
-- Pure collision rules for the Studio TextFit gate (TASK-0115). No Instances: plain tables in and out, so
-- tests/CollisionRules.spec.luau runs headless. Rectangles are in design px, rotation in degrees (positive = clockwise on
-- screen, y down), exactly as the gate reads them from Roblox GuiObjects.
--
-- Ownership: an element belongs to the nearest ancestor X whose path continues X/Group/..., which is how Menu/Shard builds a
-- control (root Frame > Group > Shard, Glow, Flash, Content). Elements of one owner compose; elements of different owners
-- must not overlap unless CollisionManifest lists the exact pair.

local CollisionRules = {}

export type Rect = { cx: number, cy: number, w: number, h: number, rot: number }

-- `path` is the element's path below the gui root, split on "/". `kind` is "shard", "label", "sticker", "spark", "flash"
-- or "glow".
export type Element = { path: { string }, kind: string, rect: Rect }

-- One approved pair, in each of the listed fixtures. Order of `a` and `b` does not matter.
export type ManifestEntry = { a: string, b: string, fixtures: { string }, reason: string }
export type Pair = { a: string, b: string, fixture: string, area: number }

export type CompareResult = {
	compared: number, -- cross-owner pairs examined
	composition: number, -- same-owner pairs that overlap (never failures)
	halo: { Pair }, -- cross-owner overlaps involving a glow (informational)
	overlaps: { Pair }, -- cross-owner overlaps (candidates for failure, minus the manifest)
}

export type MissingFixture = { entry: ManifestEntry, fixture: string }
export type ManifestResult = {
	hits: { Pair },
	unmatched: { Pair },
	unusedEntries: { ManifestEntry }, -- entries with at least one listed fixture that produced no matching pair
	missing: { MissingFixture }, -- each such fixture
}

local function corners(r: Rect): { { number } }
	local rad = math.rad(r.rot)
	local c, s = math.cos(rad), math.sin(rad)
	local hw, hh = r.w / 2, r.h / 2
	local out: { { number } } = {}
	for _, p in { { -hw, -hh }, { hw, -hh }, { hw, hh }, { -hw, hh } } do
		table.insert(out, { r.cx + p[1] * c - p[2] * s, r.cy + p[1] * s + p[2] * c })
	end
	return out
end

local function area(poly: { { number } }): number
	local sum = 0
	for i = 1, #poly do
		local p, q = poly[i], poly[i % #poly + 1]
		sum += p[1] * q[2] - q[1] * p[2]
	end
	return math.abs(sum) / 2
end

-- Sutherland-Hodgman: clip convex polygon `subject` by each edge of convex polygon `clip`. `corners` always winds the same
-- way, because rotation and size never flip a rectangle's orientation, so one inside test serves every pair.
local function clipPolygon(subject: { { number } }, clip: { { number } }): { { number } }
	local output = subject
	for i = 1, #clip do
		if #output == 0 then
			break
		end
		local a, b = clip[i], clip[i % #clip + 1]
		local ex, ey = b[1] - a[1], b[2] - a[2]
		local function inside(p: { number }): boolean
			return ex * (p[2] - a[2]) - ey * (p[1] - a[1]) >= 0
		end
		local function cross(p: { number }, q: { number }): { number }
			local dx, dy = q[1] - p[1], q[2] - p[2]
			local denom = ex * dy - ey * dx
			if denom == 0 then
				return { p[1], p[2] }
			end
			local t = (ex * (a[2] - p[2]) - ey * (a[1] - p[1])) / denom
			return { p[1] + t * dx, p[2] + t * dy }
		end
		local input = output
		output = {}
		for j = 1, #input do
			local cur, prev = input[j], input[(j - 2) % #input + 1]
			if inside(cur) then
				if not inside(prev) then
					table.insert(output, cross(prev, cur))
				end
				table.insert(output, cur)
			elseif inside(prev) then
				table.insert(output, cross(prev, cur))
			end
		end
	end
	return output
end

-- Area of the overlap of two possibly rotated rectangles. Touching edges and zero-size rectangles give 0.
function CollisionRules.rotatedRectOverlapArea(a: Rect, b: Rect): number
	if a.w <= 0 or a.h <= 0 or b.w <= 0 or b.h <= 0 then
		return 0
	end
	local pa, pb = corners(a), corners(b)
	local clipped = clipPolygon(pa, pb)
	if #clipped < 3 then
		return 0
	end
	local result = area(clipped)
	if result ~= result then
		return 0
	end
	return result
end

-- The owner of an element: the nearest ancestor X such that the path continues X/Group/..., else the element's own path.
function CollisionRules.resolveOwner(path: { string }): string
	for i = #path - 2, 1, -1 do
		if path[i + 1] == "Group" then
			return table.concat(path, "/", 1, i)
		end
	end
	return table.concat(path, "/")
end

local function key(a: string, b: string): string
	if a <= b then
		return a .. "\0" .. b
	end
	return b .. "\0" .. a
end

-- Every pair of elements: same owner overlaps count as composition; different owners are examined, and an overlap larger
-- than `minArea` is an overlap (a halo when either element is a glow). Neither input is mutated.
function CollisionRules.compare(elements: { Element }, minArea: number, fixture: string): CompareResult
	local result: CompareResult = { compared = 0, composition = 0, halo = {}, overlaps = {} }
	local owners: { string } = {}
	local paths: { string } = {}
	for i, e in elements do
		owners[i] = CollisionRules.resolveOwner(e.path)
		paths[i] = table.concat(e.path, "/")
	end
	for i = 1, #elements do
		for j = i + 1, #elements do
			local ov = CollisionRules.rotatedRectOverlapArea(elements[i].rect, elements[j].rect)
			if owners[i] == owners[j] then
				if ov > minArea then
					result.composition += 1
				end
			else
				result.compared += 1
				if ov > minArea then
					local pair: Pair = { a = paths[i], b = paths[j], fixture = fixture, area = ov }
					if elements[i].kind == "glow" or elements[j].kind == "glow" then
						table.insert(result.halo, pair)
					else
						table.insert(result.overlaps, pair)
					end
				end
			end
		end
	end
	return result
end

-- Which overlapping pairs the manifest covers (exact path pair and a listed fixture, either order) and which entries are
-- unused: an entry is unused when any fixture it lists produced no matching pair in `pairs`, so call it with every pair of
-- the run to find stale entries.
function CollisionRules.matchManifest(pairs: { Pair }, manifest: { ManifestEntry }): ManifestResult
	local byKey: { [string]: number } = {}
	for index, entry in manifest do
		for _, fixture in entry.fixtures do
			byKey[fixture .. "\1" .. key(entry.a, entry.b)] = index
		end
	end
	local used: { [string]: boolean } = {}
	local hits: { Pair } = {}
	local unmatched: { Pair } = {}
	for _, pair in pairs do
		local index = byKey[pair.fixture .. "\1" .. key(pair.a, pair.b)]
		if index then
			used[index .. "\1" .. pair.fixture] = true
			table.insert(hits, pair)
		else
			table.insert(unmatched, pair)
		end
	end
	local unusedEntries: { ManifestEntry } = {}
	local missing: { MissingFixture } = {}
	for index, entry in manifest do
		local unused = #entry.fixtures == 0
		for _, fixture in entry.fixtures do
			if not used[index .. "\1" .. fixture] then
				unused = true
				table.insert(missing, { entry = entry, fixture = fixture })
			end
		end
		if unused then
			table.insert(unusedEntries, entry)
		end
	end
	return { hits = hits, unmatched = unmatched, unusedEntries = unusedEntries, missing = missing }
end

return CollisionRules
