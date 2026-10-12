--!strict
-- Build stamp printed by both boot scripts. scripts/stamp.sh writes the git short SHA (+dirty) and a
-- UTC time into BuildStamp.txt (gitignored), which Rojo syncs as a StringValue. If the line in Output
-- doesn't match `cat games/haunted/src/shared/BuildStamp.txt`, Studio isn't running the current code.

local BuildInfo = {}

function BuildInfo.stamp(): string
	local value = script.Parent:FindFirstChild("BuildStamp")
	if value and value:IsA("StringValue") then
		return (string.gsub(value.Value, "%s+$", ""))
	end
	return "unstamped (run scripts/stamp.sh)"
end

return table.freeze(BuildInfo)
