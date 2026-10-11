--!strict
-- Ghost-train routes: closed Catmull-Rom loops through plot-local control points.
-- Shared by the server (authoritative validation, ride path, payout) and the editor preview.

local Shared = script.Parent.Parent
local Track = require(Shared.Config.Track)
local Economy = require(Shared.Config.Economy)

local TrackRules = {}

export type P = { x: number, z: number }
export type Rect = { x1: number, x2: number, z1: number, z2: number }
export type Piece = { i: number, kind: string }
export type Sampled = { points: { P }, length: number }

local function catmull(p0: P, p1: P, p2: P, p3: P, t: number): P
	local t2, t3 = t * t, t * t * t
	local function c(a: number, b: number, cc: number, d: number): number
		return 0.5 * ((2 * b) + (-a + cc) * t + (2 * a - 5 * b + 4 * cc - d) * t2 + (-a + 3 * b - 3 * cc + d) * t3)
	end
	return { x = c(p0.x, p1.x, p2.x, p3.x), z = c(p0.z, p1.z, p2.z, p3.z) }
end

local function dist(a: P, b: P): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

-- Dense polyline through the loop, then resampled at roughly `spacing` studs.
-- The returned points form a closed loop: the last point connects back to the first.
function TrackRules.sample(points: { P }, spacing: number?): Sampled
	local n = #points
	local step = spacing or Track.SampleSpacing
	if n < 2 then
		return { points = table.clone(points), length = 0 }
	end
	local dense: { P } = {}
	for i = 1, n do
		local p0 = points[(i - 2) % n + 1]
		local p1 = points[i]
		local p2 = points[i % n + 1]
		local p3 = points[(i + 1) % n + 1]
		local segs = math.max(4, math.ceil(dist(p1, p2) / 1))
		for s = 0, segs - 1 do
			table.insert(dense, catmull(p0, p1, p2, p3, s / segs))
		end
	end
	table.insert(dense, dense[1]) -- close

	local out: { P } = { dense[1] }
	local total = 0
	local carry = 0
	for i = 2, #dense do
		local a, b = dense[i - 1], dense[i]
		local d = dist(a, b)
		total += d
		carry += d
		if carry >= step then
			carry = 0
			table.insert(out, b)
		end
	end
	-- Drop a final point that sits on top of the start.
	if #out > 2 and dist(out[#out], out[1]) < step * 0.5 then
		table.remove(out)
	end
	return { points = out, length = total }
end

local function segmentsCross(a: P, b: P, c: P, d: P): boolean
	local function orient(p: P, q: P, r: P): number
		return (q.x - p.x) * (r.z - p.z) - (q.z - p.z) * (r.x - p.x)
	end
	local o1, o2 = orient(a, b, c), orient(a, b, d)
	local o3, o4 = orient(c, d, a), orient(c, d, b)
	return ((o1 > 0) ~= (o2 > 0)) and ((o3 > 0) ~= (o4 > 0)) and o1 ~= 0 and o2 ~= 0 and o3 ~= 0 and o4 ~= 0
end

export type Validation = { ok: boolean, reason: string?, sampled: Sampled? }

-- Validates untrusted control points. `bounds` is the plot-local editor rectangle.
function TrackRules.validate(points: any, pieces: any, bounds: Rect): Validation
	if type(points) ~= "table" then
		return { ok = false, reason = "No route" }
	end
	local n = #points
	if n < Track.MinPoints then
		return { ok = false, reason = `Add at least {Track.MinPoints} points` }
	end
	if n > Track.MaxPoints then
		return { ok = false, reason = `At most {Track.MaxPoints} points` }
	end
	local clean: { P } = {}
	for _, p in points do
		if type(p) ~= "table" or type(p.x) ~= "number" or type(p.z) ~= "number" or p.x ~= p.x or p.z ~= p.z then
			return { ok = false, reason = "Bad point" }
		end
		if p.x < bounds.x1 or p.x > bounds.x2 or p.z < bounds.z1 or p.z > bounds.z2 then
			return { ok = false, reason = "A point is outside your build area" }
		end
		table.insert(clean, { x = p.x, z = p.z })
	end
	for i = 1, n do
		if dist(clean[i], clean[i % n + 1]) < Track.MinPointSpacing then
			return { ok = false, reason = "Two points are too close together" }
		end
	end
	if pieces ~= nil then
		if type(pieces) ~= "table" or #pieces > Track.MaxPieces then
			return { ok = false, reason = `At most {Track.MaxPieces} special pieces` }
		end
		local used: { [number]: boolean } = {}
		for _, piece in pieces do
			if
				type(piece) ~= "table"
				or type(piece.i) ~= "number"
				or piece.i < 1
				or piece.i > n
				or piece.i % 1 ~= 0
				or type(piece.kind) ~= "string"
				or Track.Pieces[piece.kind] == nil
				or used[piece.i]
			then
				return { ok = false, reason = "Bad special piece" }
			end
			used[piece.i] = true
		end
	end
	local sampled = TrackRules.sample(clean)
	if sampled.length < Track.MinLength then
		return { ok = false, reason = `Route too short ({math.floor(sampled.length)}/{Track.MinLength} studs)` }
	end
	if sampled.length > Track.MaxLength then
		return { ok = false, reason = `Route too long ({math.floor(sampled.length)}/{Track.MaxLength} studs)` }
	end
	local margin = 3
	for _, s in sampled.points do
		if
			s.x < bounds.x1 - margin
			or s.x > bounds.x2 + margin
			or s.z < bounds.z1 - margin
			or s.z > bounds.z2 + margin
		then
			return { ok = false, reason = "The curve swings outside your build area" }
		end
	end
	local sp = sampled.points
	local m = #sp
	for i = 1, m do
		local a, b = sp[i], sp[i % m + 1]
		for j = i + 2, m do
			if not (i == 1 and j == m) then
				if segmentsCross(a, b, sp[j], sp[j % m + 1]) then
					return { ok = false, reason = "The track crosses itself" }
				end
			end
		end
	end
	-- Clearance: samples far apart along the loop must also be far apart in space (no overlapping or
	-- near-parallel passes, which the crossing test alone doesn't catch).
	local spacing = Track.SampleSpacing
	local skip = math.ceil((Track.MinClearance * 2) / spacing)
	for i = 1, m do
		for j = i + skip, m do
			if m - (j - i) > skip then
				if dist(sp[i], sp[j]) < Track.MinClearance then
					return { ok = false, reason = "Two parts of the track pass too close together" }
				end
			end
		end
	end
	return { ok = true, sampled = sampled }
end

-- Total absolute heading change around the loop, in radians.
function TrackRules.totalTurn(sampled: Sampled): number
	local sp = sampled.points
	local m = #sp
	local total = 0
	for i = 1, m do
		local a, b, c = sp[(i - 2) % m + 1], sp[i], sp[i % m + 1]
		local h1 = math.atan2(b.z - a.z, b.x - a.x)
		local h2 = math.atan2(c.z - b.z, c.x - b.x)
		local d = (h2 - h1 + math.pi) % (2 * math.pi) - math.pi
		total += math.abs(d)
	end
	return total
end

-- Route quality in [QualityMin, QualityMax]: rewards length, twistiness and special pieces.
function TrackRules.quality(sampled: Sampled, pieces: { Piece }?): number
	local lengthScore = math.clamp((sampled.length - Track.MinLength) / (Track.MaxLength - Track.MinLength), 0, 1)
	-- A plain loop turns 2*pi; extra turning (wiggles) scores up to +4*pi.
	local turnScore = math.clamp((TrackRules.totalTurn(sampled) - 2 * math.pi) / (4 * math.pi), 0, 1)
	local pieceBonus = 0
	for _, piece in (pieces or {}) :: { Piece } do
		local def = Track.Pieces[piece.kind]
		if def then
			pieceBonus += def.quality
		end
	end
	local q = 0.9 + lengthScore * 0.12 + turnScore * 0.08 + pieceBonus
	return math.clamp(q, Track.QualityMin, Track.QualityMax)
end

function TrackRules.nearestDistance(sampled: Sampled, x: number, z: number): number
	local best = math.huge
	for _, s in sampled.points do
		local d = math.sqrt((s.x - x) ^ 2 + (s.z - z) ^ 2)
		if d < best then
			best = d
		end
	end
	return best
end

export type ExhibitInput = { rarity: string, variantMultiplier: number, x: number, z: number }
export type Payout =
	{ total: number, base: number, tier: number, quality: number, exhibitBonus: number, counted: number }

function TrackRules.payout(
	sampled: Sampled,
	pieces: { Piece }?,
	tierMultiplier: number,
	exhibits: { ExhibitInput }
): Payout
	local bonus = 0
	local counted = 0
	for _, e in exhibits do
		if TrackRules.nearestDistance(sampled, e.x, e.z) <= Economy.ExhibitRange then
			bonus += (Economy.ExhibitRarityWeight[e.rarity] or 0) * e.variantMultiplier
			counted += 1
		end
	end
	local quality = TrackRules.quality(sampled, pieces)
	local total = math.floor(Economy.RideBasePayout * tierMultiplier * quality * (1 + bonus) + 0.5)
	return {
		total = total,
		base = Economy.RideBasePayout,
		tier = tierMultiplier,
		quality = quality,
		exhibitBonus = bonus,
		counted = counted,
	}
end

-- Position and heading at distance `d` along the loop (wraps).
function TrackRules.pointAt(sampled: Sampled, d: number): (P, P)
	local sp = sampled.points
	local m = #sp
	local acc = 0
	for i = 1, m do
		local a, b = sp[i], sp[i % m + 1]
		local seg = dist(a, b)
		if acc + seg >= d or i == m then
			local t = if seg > 0 then math.clamp((d - acc) / seg, 0, 1) else 0
			local pos = { x = a.x + (b.x - a.x) * t, z = a.z + (b.z - a.z) * t }
			local dir = if seg > 0 then { x = (b.x - a.x) / seg, z = (b.z - a.z) / seg } else { x = 0, z = -1 }
			return pos, dir
		end
		acc += seg
	end
	return sp[1], { x = 0, z = -1 }
end

-- Loop length measured over the resampled points (what the cart actually travels).
function TrackRules.loopLength(sampled: Sampled): number
	local sp = sampled.points
	local total = 0
	for i = 1, #sp do
		total += dist(sp[i], sp[i % #sp + 1])
	end
	return total
end

return TrackRules
