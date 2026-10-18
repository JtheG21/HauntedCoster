--!strict
-- Equippable capture effects (TASK-0063). Pure. The effect is a client-only burst for the player who just
-- captured; nothing here is read by capture timing, success, the meter, retaliation or income.

local CosmeticRules = require(script.Parent.CosmeticRules)

local CaptureFxRules = {}

CaptureFxRules.PreviewCooldown = 1.5 -- seconds between local previews, so replaying can't flood the screen

export type Request = { id: string? }
export type Payload = { id: string, position: Vector3 }

-- Untrusted remote argument: an item ID to equip, or nil to remove.
function CaptureFxRules.parse(id: any): (Request?, string?)
	if id ~= nil and not CosmeticRules.isId(id) then
		return nil, "Something went wrong. Try again."
	end
	return { id = id :: string? }, nil
end

local MESSAGES: { [string]: string } = {
	notOwned = "You don't own that effect yet.",
	unknown = "That effect isn't available.",
	wrongCategory = "That isn't a capture effect.",
}

function CaptureFxRules.message(reason: string?): string
	return MESSAGES[reason or ""] or "Something went wrong. Try again."
end

-- The effect to play now: the saved choice, only if still owned, listed and a capture effect. Anything else
-- means "no effect", never an error, so a catalog change can't break a capture.
function CaptureFxRules.resolve(cosmetics: CosmeticRules.State?, catalog: CosmeticRules.Catalog): string?
	local id = cosmetics and cosmetics.captureEffect
	if not (cosmetics and id) then
		return nil
	end
	local item = catalog.Items[id]
	if item and item.category == "CaptureEffect" and cosmetics.entitlements[id] then
		return id
	end
	return nil
end

-- Client side: the server's payload checked again before it is used.
function CaptureFxRules.parsePayload(info: any, known: { [string]: any }, from: Vector3, maxDistance: number): Payload?
	if type(info) ~= "table" then
		return nil
	end
	local id, position = info.id, info.position
	if type(id) ~= "string" or known[id] == nil then
		return nil
	end
	if typeof(position) ~= "Vector3" then
		return nil
	end
	local p = position :: Vector3
	if p ~= p or (p - from).Magnitude > maxDistance then
		return nil
	end
	return { id = id, position = p }
end

return CaptureFxRules
