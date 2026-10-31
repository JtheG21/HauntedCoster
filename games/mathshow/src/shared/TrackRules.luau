--!strict
-- Six rank tracks: 3 modes x 2 formats (blueprint section 5). A playlist (casual / ranked) is not part of the track.
-- TrackId is "<mode>:<format>". Pure, strict parsing.

export type ModeId = "groupBattle" | "team3v3" | "blitz"
export type FormatId = "direct" | "choice"
export type PlaylistId = "casual" | "ranked"
export type TrackId = string

local MODES: { ModeId } = { "groupBattle", "team3v3", "blitz" }
local FORMATS: { FormatId } = { "direct", "choice" }

local TrackRules = {}

local function isMode(v: any): boolean
	return v == "groupBattle" or v == "team3v3" or v == "blitz"
end

local function isFormat(v: any): boolean
	return v == "direct" or v == "choice"
end

-- The six tracks in a stable order (mode order, then format order).
function TrackRules.all(): { TrackId }
	local out = {}
	for _, m in MODES do
		for _, f in FORMATS do
			table.insert(out, `{m}:{f}`)
		end
	end
	return out
end

function TrackRules.make(mode: any, format: any): TrackId?
	if not (isMode(mode) and isFormat(format)) then
		return nil
	end
	return `{mode}:{format}`
end

-- Strict: unknown, extra parts, empty and wrong-case input return nil.
function TrackRules.parse(id: any): (ModeId?, FormatId?)
	if type(id) ~= "string" then
		return nil, nil
	end
	local mode, format = id:match("^(%w+):(%w+)$")
	if mode and format and isMode(mode) and isFormat(format) then
		return mode :: ModeId, format :: FormatId
	end
	return nil, nil
end

function TrackRules.isRanked(playlist: any): boolean
	return playlist == "ranked"
end

return TrackRules
