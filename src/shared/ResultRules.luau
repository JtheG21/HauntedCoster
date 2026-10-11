--!strict
-- Pure finale and category-result rules (TASK-0007). Players are identified by UserId.

local ResultRules = {}

export type Combat = {
	winner: number?, -- the last player standing
	draw: { number }, -- players sharing the result when there is no single winner
}

-- Ring-out test: below the deck by `depth`, outside the horizontal radius, or a NaN position.
function ResultRules.isRingOut(position: Vector3, center: Vector3, topY: number, depth: number, radius: number): boolean
	if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z then
		return true
	end
	if position.Y < topY - depth then
		return true
	end
	local flat = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
	return flat.Magnitude > radius
end

-- Whether the finale is over. With 2+ starters it ends when at most one is left; a solo finale only
-- ends when that player is out. The time limit always ends it.
function ResultRules.finaleOver(starters: number, alive: number, elapsed: number, maxSeconds: number): boolean
	if elapsed >= maxSeconds or alive <= 0 then
		return true
	end
	return starters >= 2 and alive <= 1
end

-- Combat result. `survivors` are still in when the finale ends; `lastOut` are the players eliminated
-- in the final elimination poll (eliminated together); `starters` is how many began the finale.
-- One survivor wins. Several survivors (time ran out) share a draw. No survivors: the players who
-- went out together last share a draw; a single last-out player outlasted everyone else and wins if
-- others took part (audit F1), but a solo player who falls wins nothing.
function ResultRules.combat(survivors: { number }, lastOut: { number }, starters: number): Combat
	if #survivors == 1 then
		return { winner = survivors[1], draw = {} }
	end
	if #survivors == 0 and #lastOut == 1 and starters >= 2 then
		return { winner = lastOut[1], draw = {} }
	end
	local pool = if #survivors > 1 then survivors elseif #lastOut > 1 then lastOut else {}
	local draw = table.clone(pool)
	table.sort(draw)
	return { winner = nil, draw = draw }
end

-- Speed: the first obby finisher (finish order is already deterministic).
function ResultRules.speed(finishOrder: { number }): number?
	return finishOrder[1]
end

-- Teamwork: the most gate contributions. Ties go to the earlier finisher, then the lower UserId.
-- Nobody wins with zero contributions.
function ResultRules.teamwork(contributions: { [number]: number }, finishOrder: { number }): number?
	local function rank(id: number): number
		return table.find(finishOrder, id) or math.huge
	end
	local best: number? = nil
	local bestCount = 0
	for id, count in contributions do
		if count <= 0 or count ~= count then
			continue
		end
		local better = count > bestCount
		if not better and count == bestCount and best ~= nil then
			local a, b = rank(id), rank(best)
			better = a < b or (a == b and id < best)
		end
		if better then
			best, bestCount = id, count
		end
	end
	return best
end

return ResultRules
