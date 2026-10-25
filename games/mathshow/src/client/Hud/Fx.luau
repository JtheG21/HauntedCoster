--!strict
-- Cosmetic tweens only. Every call is pcall-isolated, failures warn and leave the Hud readable; gameplay
-- code (state, submit) never depends on anything here.

local TweenService = game:GetService("TweenService")

local Fx = {}

local running: { [Instance]: Tween? } = {}

local function guarded(name: string, fn: () -> ()): boolean
	local ok, err = pcall(fn :: any)
	if not ok then
		warn(`[MathShow] Hud Fx.{name} failed: {err}`)
	end
	return ok
end

-- Fades a label's text in. If anything fails the text is left fully visible.
function Fx.fadeIn(label: TextLabel, seconds: number)
	local ok = guarded("fadeIn", function()
		local previous = running[label]
		if previous then
			previous:Cancel()
		end
		label.TextTransparency = 1
		local tween =
			TweenService:Create(label, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0,
			})
		running[label] = tween
		tween:Play()
	end)
	if not ok then
		label.TextTransparency = 0
	end
end

-- Stops any tween on the label and shows it fully.
function Fx.reset(label: TextLabel)
	guarded("reset", function()
		local previous = running[label]
		if previous then
			previous:Cancel()
			running[label] = nil
		end
		label.TextTransparency = 0
	end)
end

function Fx.destroy()
	guarded("destroy", function()
		for _, tween in running do
			if tween then
				tween:Cancel()
			end
		end
		table.clear(running)
	end)
end

return Fx
