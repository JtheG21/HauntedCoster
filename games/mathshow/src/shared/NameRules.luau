--!strict
-- Pure name rules for the menu. No Instances. Nothing here throws on bad input.

local MenuConfig = require(script.Parent.MenuConfig)

local ELLIPSIS = "\u{2026}"

local NameRules = {}

-- At most NameMax characters: longer names keep the first NameMax - 1 and gain an ellipsis.
function NameRules.truncateName(name: string): string
	if typeof(name) ~= "string" then
		return ""
	end
	local max = MenuConfig.NameMax
	local length = utf8.len(name)
	if length == nil then
		-- Invalid UTF-8: byte-safe cut.
		if #name <= max then
			return name
		end
		return string.sub(name, 1, max - 1) .. ELLIPSIS
	end
	if length <= max then
		return name
	end
	local cut = utf8.offset(name, max) -- byte index of character `max`, i.e. the first one dropped
	return string.sub(name, 1, (cut :: number) - 1) .. ELLIPSIS
end

return NameRules
