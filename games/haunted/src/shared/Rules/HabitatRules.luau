--!strict
-- Pure geometry rules for habitat modules (ADR-0007): distances to paths, the shared footprint, gate
-- corridors, and `validate`, which lists every way a module breaks the module contract.

local Shared = script.Parent.Parent
local World = require(Shared.Config.World)
local Habitats = require(Shared.Config.Habitats)
local Monsters = require(Shared.Config.Monsters)
local Variants = require(Shared.Config.Variants)

local HabitatRules = {}

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

-- Distance on the ground from (x, z) to the segment a-b.
function HabitatRules.distToSegment(x: number, z: number, a: Vector3, b: Vector3): number
	local p, pa, pb = Vector2.new(x, z), flat(a), flat(b)
	local ab = pb - pa
	local len2 = ab:Dot(ab)
	local t = if len2 > 0 then math.clamp((p - pa):Dot(ab) / len2, 0, 1) else 0
	return (p - (pa + ab * t)).Magnitude
end

-- Clearance from (x, z) to the nearest path edge (negative when on a path).
function HabitatRules.pathClearance(habitat: Habitats.Habitat, x: number, z: number): number
	local best = math.huge
	for _, path in habitat.paths do
		for i = 1, #path.points - 1 do
			local d = HabitatRules.distToSegment(x, z, path.points[i], path.points[i + 1]) - path.width / 2
			if d < best then
				best = d
			end
		end
	end
	return best
end

-- Inside the shared footprint, with `margin` studs to spare.
function HabitatRules.inFootprint(x: number, z: number, margin: number?): boolean
	return World.hubDistance(x, z) <= World.Hub.moduleRadius - (margin or 0)
end

function HabitatRules.rectInFootprint(r: World.Rect): boolean
	for _, c in { { r.x1, r.z1 }, { r.x1, r.z2 }, { r.x2, r.z1 }, { r.x2, r.z2 } } do
		if not HabitatRules.inFootprint(c[1], c[2]) then
			return false
		end
	end
	return true
end

-- Within a gate corridor: inside the footprint, within `gateCorridor` studs of the wall along the gate's
-- radial line, and within half a gate width of that line.
function HabitatRules.inGateCorridor(x: number, z: number): (boolean, number?)
	local hub = World.Hub
	for gate = 1, #hub.gateAngles do
		local inner = World.gatePoint(gate, hub.wallRadius - hub.gateCorridor)
		local outer = World.gatePosition(gate)
		if HabitatRules.distToSegment(x, z, inner, outer) <= hub.gateWidth / 2 then
			return true, gate
		end
	end
	return false, nil
end

local function rectHitsCorridor(r: World.Rect): boolean
	-- Sample the rect edges and interior on a 2-stud grid; corridors are 16 studs wide.
	local x = r.x1
	while x <= r.x2 do
		local z = r.z1
		while z <= r.z2 do
			if HabitatRules.inGateCorridor(x, z) then
				return true
			end
			z += 2
		end
		x += 2
	end
	return false
end

-- Every problem with a module, as readable strings. An empty list means it fits the contract.
function HabitatRules.validate(habitat: Habitats.Habitat): { string }
	local problems: { string } = {}
	local function bad(s: string)
		table.insert(problems, `{habitat.id}: {s}`)
	end
	local ids: { [string]: boolean } = {}
	for _, zone in habitat.zones do
		if ids[zone.id] then
			bad(`duplicate zone id {zone.id}`)
		end
		ids[zone.id] = true
		local r = zone.rect
		if r.x1 >= r.x2 or r.z1 >= r.z2 then
			bad(`zone {zone.id} has an empty rect`)
		end
		if not HabitatRules.rectInFootprint(r) then
			bad(`zone {zone.id} leaves the footprint`)
		end
		if rectHitsCorridor(r) then
			bad(`zone {zone.id} overlaps a gate corridor`)
		end
		if next(zone.spawns) == nil then
			bad(`zone {zone.id} spawns nothing`)
		end
		for species, weight in zone.spawns do
			if not Monsters.Species[species] then
				bad(`zone {zone.id} spawns unknown species {species}`)
			end
			if type(weight) ~= "number" or weight <= 0 then
				bad(`zone {zone.id} has a bad weight for {species}`)
			end
		end
	end
	if #habitat.landmarks < 2 then
		bad("needs at least two landmarks")
	end
	local landmarkIds: { [string]: boolean } = {}
	for _, lm in habitat.landmarks do
		if landmarkIds[lm.id] then
			bad(`duplicate landmark id {lm.id}`)
		end
		landmarkIds[lm.id] = true
		local zoneId = lm.zone
		if zoneId then
			local zone: World.Zone? = nil
			for _, z in habitat.zones do
				if z.id == zoneId then
					zone = z
				end
			end
			if not zone then
				bad(`landmark {lm.id} names missing zone {zoneId}`)
			elseif not World.inRect(zone.rect, lm.position.X, lm.position.Z) then
				bad(`landmark {lm.id} isn't inside its zone {zoneId}`)
			end
		end
		if not HabitatRules.inFootprint(lm.position.X, lm.position.Z, 4) then
			bad(`landmark {lm.id} leaves the footprint`)
		end
		if HabitatRules.inGateCorridor(lm.position.X, lm.position.Z) then
			bad(`landmark {lm.id} blocks a gate corridor`)
		end
		if HabitatRules.pathClearance(habitat, lm.position.X, lm.position.Z) < 0 then
			bad(`landmark {lm.id} stands on a path`)
		end
	end
	local paths: { [string]: Habitats.Path } = {}
	for _, path in habitat.paths do
		paths[path.id] = path
		for _, p in path.points do
			if not HabitatRules.inFootprint(p.X, p.Z) then
				bad(`path {path.id} leaves the footprint`)
				break
			end
		end
	end
	if #habitat.gatePaths ~= #World.Hub.gateAngles then
		bad("needs one gate path per hub gate")
	end
	for gate, id in habitat.gatePaths do
		local path = paths[id]
		local inner = World.gatePoint(gate, World.Hub.moduleRadius)
		if not path then
			bad(`gate {gate} path {id} is missing`)
		elseif (flat(path.points[1]) - flat(inner)).Magnitude > 4 then
			bad(`gate {gate} path {id} doesn't start at its gate`)
		end
	end
	local crypt = habitat.crypt
	if crypt then
		if not HabitatRules.rectInFootprint(crypt.rect) then
			bad("crypt leaves the footprint")
		end
		if rectHitsCorridor(crypt.rect) then
			bad("crypt overlaps a gate corridor")
		end
		for _, zone in habitat.zones do
			local r = zone.rect
			local inside = r.x1 > crypt.rect.x1
				and r.x2 < crypt.rect.x2
				and r.z1 > crypt.rect.z1
				and r.z2 < crypt.rect.z2
			if zone.gated and not inside then
				bad(`gated zone {zone.id} isn't inside the crypt walls`)
			end
		end
	end
	local starter = habitat.starter
	if starter then
		local zone: World.Zone? = nil
		for _, z in habitat.zones do
			if z.id == starter.zone then
				zone = z
			end
		end
		if not zone then
			bad(`starter zone {starter.zone} is missing`)
		elseif not World.inRect(zone.rect, starter.at.X, starter.at.Z) then
			bad("starter spawn isn't inside its zone")
		end
	end
	return problems
end

-- Zones of `habitat` where an escaped monster may go back to: its species spawns there and its variant may
-- appear there. An Ashen monster only ever returns to the Sealed Crypt (ADR-0006 §2); in a habitat without
-- one there is nowhere to go, and the spawner repopulates later.
function HabitatRules.escapedRespawnZones(habitat: Habitats.Habitat, speciesId: string, variantId: string): { string }
	local variant = Variants.ById[variantId]
	local out = {}
	for _, zone in habitat.zones do
		if
			zone.spawns[speciesId] and (variant == nil or variant.zones == nil or table.find(variant.zones, zone.id))
		then
			table.insert(out, zone.id)
		end
	end
	return out
end

local function onlyGated(zoneIds: { string }): boolean
	if #zoneIds == 0 then
		return false
	end
	for _, id in zoneIds do
		local zone = Habitats.anyZoneById(id)
		if not (zone and zone.gated) then
			return false
		end
	end
	return true
end

-- True when capturing this monster needs the crypt open (house tier). Not only a monster standing in a gated
-- zone: a crypt species (the Bell Wraith) or a crypt-only variant (Ashen) that ended up anywhere else is still
-- gated, so a misplaced spawn can never hand a tier-0 player a crypt monster (TASK-0021).
function HabitatRules.needsCrypt(zoneId: string?, speciesId: string, variantId: string): boolean
	local zone = if zoneId then Habitats.zoneById(zoneId) else nil
	if zone and zone.gated then
		return true
	end
	local variant = Variants.ById[variantId]
	if variant and variant.zones and onlyGated(variant.zones) then
		return true
	end
	local homes = {}
	for _, h in Habitats.List do
		for _, z in h.zones do
			if z.spawns[speciesId] then
				table.insert(homes, z.id)
			end
		end
	end
	return onlyGated(homes)
end

return HabitatRules
