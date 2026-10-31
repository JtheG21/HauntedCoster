--!strict
-- Motion presets for the Shards Hud. Each mirrors a keyframe set in the design (MathShowHudV2 KF / enter()).
--
-- Rules every preset follows:
--  * Cosmetic only. Every public function is pcall-isolated and warns on failure; a fault never reaches input,
--    submit or the Heartbeat countdown, and nothing here yields (no Completed:Wait: sequences chain with
--    Completed:Once).
--  * Fx moves an element relative to its REST state (position, rotation, size, transparency), captured once
--    the first time the element is touched. Repeated shakes cannot drift, and View never has to re-place anything.
--  * A new call on an element cancels what that element was doing on the same channel (pos / scale / fade).
--  * Elements Fx scales or pops own a UIScale child (View puts it there, AnchorPoint at the centre). A missing
--    UIScale is an error that warns; Fx does not quietly create one.
--  * GuiService.ReducedMotionEnabled: entrances and loops are skipped and the element snaps to its final state.

local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Fx = {}

type Props = { [string]: any }

export type IntermissionParts = {
	Card: GuiObject,
	Countdown: GuiObject?, -- only on the "get ready" screen
	Tag: GuiObject,
	Title: GuiObject,
	Sub: GuiObject,
}
export type QuestionParts = {
	Problem: GuiObject,
	Tag: GuiObject,
	ProblemText: GuiObject,
	Seconds: GuiObject,
	TimerFill: GuiObject, -- a clipping Frame whose width grows from 0
	InputRow: GuiObject,
	Submit: GuiObject,
}
export type RevealParts = {
	Problem: GuiObject,
	ProblemFlash: GuiObject,
	Answer: GuiObject,
	Chips: { GuiObject }, -- the chips on screen, in order
}
export type ToastParts = {
	Toast: GuiObject,
	ToastFlash: GuiObject,
	Sparks: { GuiObject },
	InputRow: GuiObject?,
}
export type ResultsParts = {
	Pod1: GuiObject,
	Pod2: GuiObject,
	Pod3: GuiObject,
	Pod1Flash: GuiObject,
	Rows: { GuiObject }, -- the list rows on screen, in order
}
export type TickParts = {
	Seconds: GuiObject,
	Problem: GuiObject,
	CountNumber: GuiObject,
}

------------------------------------------------------------------------------------------------------------------
-- Machinery
------------------------------------------------------------------------------------------------------------------

type Rest = { position: UDim2, rotation: number, size: UDim2, alpha: Props }
type Slot = { token: number, tweens: { Tween } }

local EASE_OUT = Enum.EasingStyle.Quart
local TICK_SCALE = 1.08
local ALERT_SCALE = 1.45
local ALERT_SECONDS = 3

local rests: { [Instance]: Rest } = setmetatable({}, { __mode = "k" }) :: any
local slots: { [Instance]: { [string]: Slot } } = setmetatable({}, { __mode = "k" }) :: any
local nextToken = 0

local function safe(name: string, fn: () -> ())
	local ok, err = pcall(fn :: any)
	if not ok then
		warn(`[MathShow] Hud Fx.{name} failed: {err}`)
	end
end

-- Calls fn after `delay` seconds without yielding the caller. Errors warn.
local function later(name: string, delay: number, fn: () -> ())
	if delay <= 0 then
		safe(name, fn)
		return
	end
	task.delay(delay, function()
		safe(name, fn)
	end)
end

local reducedOverride = false -- the menu's REDUCED MOTION setting (Fx.setReducedMotion)

local function reduced(): boolean
	if reducedOverride then
		return true
	end
	local ok, value = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	return ok and value == true
end

local function ti(seconds: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): TweenInfo
	return TweenInfo.new(seconds, style or EASE_OUT, direction or Enum.EasingDirection.Out)
end

-- The transparency properties Fx fades on an element, with their final (rest) values.
local function alphaOf(g: GuiObject): Props
	if g:IsA("CanvasGroup") then
		return { GroupTransparency = 0 }
	elseif g:IsA("TextLabel") or g:IsA("TextButton") then
		return { TextTransparency = g.TextTransparency, TextStrokeTransparency = g.TextStrokeTransparency }
	elseif g:IsA("ImageLabel") then
		return { ImageTransparency = g.ImageTransparency }
	elseif g:IsA("Frame") and g.BackgroundTransparency < 1 then
		return { BackgroundTransparency = g.BackgroundTransparency }
	end
	return {}
end

local function restOf(g: GuiObject): Rest
	local rest = rests[g]
	if rest == nil then
		rest = { position = g.Position, rotation = g.Rotation, size = g.Size, alpha = alphaOf(g) }
		rests[g] = rest
	end
	return rest :: Rest
end

local function scaleOf(g: GuiObject): UIScale
	local scale = g:FindFirstChildOfClass("UIScale")
	if scale == nil then
		error(`{g:GetFullName()} has no UIScale`)
	end
	return scale
end

local function slotOf(owner: Instance, channel: string): Slot
	local bySlot = slots[owner]
	if bySlot == nil then
		bySlot = {}
		slots[owner] = bySlot
	end
	local slot = (bySlot :: any)[channel]
	if slot == nil then
		slot = { token = 0, tweens = {} }
		(bySlot :: any)[channel] = slot
	end
	return slot
end

-- Cancels whatever `owner` is doing on these channels and returns the token that owns them from now on.
local function claim(owner: Instance, channels: { string }): number
	nextToken += 1
	for _, channel in channels do
		local slot = slotOf(owner, channel)
		for _, tween in slot.tweens do
			tween:Cancel()
		end
		table.clear(slot.tweens)
		slot.token = nextToken
	end
	return nextToken
end

local function alive(owner: Instance, channel: string, token: number): boolean
	return slotOf(owner, channel).token == token
end

-- Plays a tween on `target` under (owner, channel). onDone runs once, only if it finished and nobody claimed
-- the channel meanwhile.
local function play(
	owner: Instance,
	channel: string,
	token: number,
	target: Instance,
	info: TweenInfo,
	goal: Props,
	onDone: (() -> ())?
): Tween
	local tween = TweenService:Create(target, info, goal)
	table.insert(slotOf(owner, channel).tweens, tween)
	if onDone then
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and alive(owner, channel, token) then
				safe("step", onDone)
			end
		end)
	end
	tween:Play()
	return tween
end

local function hide(g: GuiObject)
	local rest = restOf(g)
	for prop in rest.alpha do
		(g :: any)[prop] = 1
	end
end

local function fadeInGoal(g: GuiObject): Props
	return table.clone(restOf(g).alpha)
end

-- Final state: rest position, rotation, size, scale and transparency, nothing running.
local function restore(g: GuiObject)
	claim(g, { "pos", "scale", "fade" })
	local rest = restOf(g)
	g.Position, g.Rotation, g.Size = rest.position, rest.rotation, rest.size
	local scale = g:FindFirstChildOfClass("UIScale")
	if scale then
		scale.Scale = 1
	end
	for prop, value in rest.alpha do
		(g :: any)[prop] = value
	end
end

-- Like safe, but a fault also puts the element back in its final state so it can never stay invisible.
local function guarded(name: string, g: GuiObject, fn: () -> ())
	local ok, err = pcall(fn :: any)
	if not ok then
		warn(`[MathShow] Hud Fx.{name} failed: {err}`)
		pcall(restore, g)
	end
end

-- Chains position tweens: each target after the last, never yielding.
local function chain(g: GuiObject, token: number, targets: { UDim2 }, seconds: number, style: Enum.EasingStyle)
	local index = 0
	local function step()
		index += 1
		local target: UDim2? = targets[index]
		if target == nil or not alive(g, "pos", token) then
			return
		end
		play(g, "pos", token, g, ti(seconds, style), { Position = target }, step)
	end
	step()
end

------------------------------------------------------------------------------------------------------------------
-- Presets
------------------------------------------------------------------------------------------------------------------

-- Two-stage move: overshoot at 55% of the time, then settle with Back easing. dx, dy, rot are the start offsets.
local function settle(g: GuiObject, dx: number, dy: number, rot: number, scale: number, t: number, delay: number)
	local rest = restOf(g)
	local uiScale = scaleOf(g)
	local token = claim(g, { "pos", "scale", "fade" })
	if reduced() then
		restore(g)
		return
	end
	g.Position = rest.position + UDim2.fromOffset(dx, dy)
	g.Rotation = rest.rotation + rot
	uiScale.Scale = scale
	hide(g)
	later("settle", delay, function()
		if not alive(g, "pos", token) then
			return
		end
		local overshoot = rest.position + UDim2.fromOffset(-dx * 0.07, 0)
		local first = t * 0.55
		play(g, "fade", token, g, ti(first), fadeInGoal(g), nil)
		play(g, "scale", token, uiScale, ti(first), { Scale = 1 - (scale - 1) * 0.2 }, nil)
		play(g, "pos", token, g, ti(first), { Position = overshoot, Rotation = rest.rotation - rot * 0.17 }, function()
			local back = ti(t * 0.45, Enum.EasingStyle.Back)
			play(g, "pos", token, g, back, { Position = rest.position, Rotation = rest.rotation }, nil)
			play(g, "scale", token, uiScale, back, { Scale = 1 }, nil)
		end)
	end)
end

function Fx.slam(g: GuiObject, delay: number?)
	guarded("slam", g, function()
		settle(g, -60, 10, -7, 1.08, 0.52, delay or 0)
	end)
end

-- A rank badge lands: scale 2.4 and a 12 degree tilt settle to rest with the same two-stage ease as slam (TASK-0101; used by
-- the Skill Test result, TASK-0102). Reduced motion: snaps to the final state.
function Fx.badgeSlam(g: GuiObject, delay: number?)
	guarded("badgeSlam", g, function()
		settle(g, 0, 0, -12, 2.4, 0.5, delay or 0)
	end)
end

function Fx.slamRight(g: GuiObject, delay: number?)
	guarded("slamRight", g, function()
		settle(g, 60, -10, 9, 1.1, 0.56, delay or 0)
	end)
end

function Fx.flyLeft(g: GuiObject, delay: number?)
	guarded("flyLeft", g, function()
		settle(g, -280, 0, -12, 1, 0.62, delay or 0)
	end)
end

-- Fade in while sliding from an offset to rest.
local function enter(name: string, g: GuiObject, dx: number, dy: number, seconds: number, delay: number)
	local rest = restOf(g)
	local token = claim(g, { "pos", "fade" })
	if reduced() then
		restore(g)
		return
	end
	g.Position = rest.position + UDim2.fromOffset(dx, dy)
	hide(g)
	later(name, delay, function()
		if not alive(g, "pos", token) then
			return
		end
		play(g, "pos", token, g, ti(seconds), { Position = rest.position }, nil)
		play(g, "fade", token, g, ti(seconds), fadeInGoal(g), nil)
	end)
end

function Fx.rowIn(g: GuiObject, delay: number?)
	guarded("rowIn", g, function()
		enter("rowIn", g, 60, 0, 0.34, delay or 0)
	end)
end

function Fx.slide(g: GuiObject, delay: number?)
	guarded("slide", g, function()
		enter("slide", g, -18, 0, 0.28, delay or 0)
	end)
end

function Fx.rise(g: GuiObject, delay: number?)
	guarded("rise", g, function()
		enter("rise", g, 0, 14, 0.34, delay or 0)
	end)
end

-- Fade only (subtitle).
function Fx.fade(g: GuiObject, delay: number?)
	guarded("fade", g, function()
		local token = claim(g, { "fade" })
		if reduced() then
			restore(g)
			return
		end
		hide(g)
		later("fade", delay or 0, function()
			if alive(g, "fade", token) then
				play(g, "fade", token, g, ti(0.4), fadeInGoal(g), nil)
			end
		end)
	end)
end

-- Back-eased scale from 0.4 (the score value, the seconds number, the toast, buttons).
function Fx.pop(g: GuiObject, delay: number?, seconds: number?)
	guarded("pop", g, function()
		local scale = scaleOf(g)
		local token = claim(g, { "scale", "fade" })
		if reduced() then
			restore(g)
			return
		end
		scale.Scale = 0.4
		hide(g)
		later("pop", delay or 0, function()
			if not alive(g, "scale", token) then
				return
			end
			local info = ti(seconds or 0.36, Enum.EasingStyle.Back)
			play(g, "scale", token, scale, info, { Scale = 1 }, nil)
			play(g, "fade", token, g, ti(0.18), fadeInGoal(g), nil)
		end)
	end)
end

-- Starts big and eases to rest.
function Fx.pulse(g: GuiObject, amount: number?, seconds: number?, delay: number?)
	safe("pulse", function()
		local scale = scaleOf(g)
		local token = claim(g, { "scale" })
		if reduced() then
			scale.Scale = 1
			return
		end
		later("pulse", delay or 0, function()
			if alive(g, "scale", token) then
				scale.Scale = amount or ALERT_SCALE
				play(g, "scale", token, scale, ti(seconds or 0.42), { Scale = 1 }, nil)
			end
		end)
	end)
end

function Fx.shake(g: GuiObject, delay: number?)
	safe("shake", function()
		local base = restOf(g).position
		local token = claim(g, { "pos" })
		g.Position = base
		if reduced() then
			return
		end
		later("shake", delay or 0, function()
			local targets: { UDim2 } = {}
			for _, dx in { -10, 8, -6, 3, 0 } do
				table.insert(targets, base + UDim2.fromOffset(dx, 0))
			end
			if alive(g, "pos", token) then
				chain(g, token, targets, 0.07, Enum.EasingStyle.Sine)
			end
		end)
	end)
end

function Fx.shiver(g: GuiObject)
	safe("shiver", function()
		local base = restOf(g).position
		local token = claim(g, { "pos" })
		g.Position = base
		if reduced() then
			return
		end
		local targets: { UDim2 } = {}
		for _, d in { Vector2.new(-3, 1), Vector2.new(3, -1), Vector2.new(-2, 0), Vector2.zero } do
			table.insert(targets, base + UDim2.fromOffset(d.X, d.Y))
		end
		chain(g, token, targets, 0.05, Enum.EasingStyle.Sine)
	end)
end

-- White overlay shaped like its shard (an ImageLabel with the shard image, ImageColor3 white).
function Fx.flash(overlay: GuiObject, delay: number?)
	safe("flash", function()
		local label = overlay :: ImageLabel
		local token = claim(overlay, { "fade" })
		label.ImageTransparency = 1
		if reduced() then
			return
		end
		later("flash", delay or 0, function()
			if alive(overlay, "fade", token) then
				label.ImageTransparency = 0.15
				play(overlay, "fade", token, label, ti(0.42), { ImageTransparency = 1 }, nil)
			end
		end)
	end)
end

-- Reveal answer: Back-eased scale and fade. Roblox has no scaleY, so this grows evenly from small.
function Fx.flip(g: GuiObject, delay: number?)
	guarded("flip", g, function()
		local scale = scaleOf(g)
		local token = claim(g, { "scale", "fade" })
		if reduced() then
			restore(g)
			return
		end
		scale.Scale = 0.2
		hide(g)
		later("flip", delay or 0, function()
			if alive(g, "scale", token) then
				play(g, "scale", token, scale, ti(0.38, Enum.EasingStyle.Back), { Scale = 1 }, nil)
				play(g, "fade", token, g, ti(0.2), fadeInGoal(g), nil)
			end
		end)
	end)
end

-- Timer bar reveal: the clipping Frame grows from 0 to its full width.
function Fx.grow(clip: GuiObject, delay: number?)
	safe("grow", function()
		local rest = restOf(clip)
		local token = claim(clip, { "pos" })
		if reduced() then
			clip.Size = rest.size
			return
		end
		clip.Size = UDim2.new(UDim.new(0, 0), rest.size.Y)
		later("grow", delay or 0, function()
			if alive(clip, "pos", token) then
				play(clip, "pos", token, clip, ti(0.52), { Size = rest.size }, nil)
			end
		end)
	end)
end

-- Correct answer: small white diamonds fly out from the toast and fade. Sparks rest invisible.
local BURST = {
	Vector2.new(-46, -30),
	Vector2.new(10, -44),
	Vector2.new(70, -26),
	Vector2.new(-30, 34),
	Vector2.new(120, 30),
}
function Fx.burst(sparks: { GuiObject }, delay: number?)
	safe("burst", function()
		if reduced() then
			return
		end
		for index, spark in sparks do
			local rest = restOf(spark)
			local token = claim(spark, { "pos", "fade" })
			local offset = BURST[index] or Vector2.zero
			local frame = spark :: Frame
			later("burst", delay or 0, function()
				if not alive(spark, "pos", token) then
					return
				end
				frame.Position, frame.Rotation, frame.BackgroundTransparency = rest.position, rest.rotation, 0
				play(spark, "fade", token, frame, ti(0.64), { BackgroundTransparency = 1 }, nil)
				play(spark, "pos", token, frame, ti(0.64), {
					Position = rest.position + UDim2.fromOffset(offset.X, offset.Y),
					Rotation = rest.rotation + 90,
				}, function()
					frame.Position, frame.Rotation = rest.position, rest.rotation
				end)
			end)
		end
	end)
end

------------------------------------------------------------------------------------------------------------------
-- Loops: each returns a stop function; call it when the element hides.
------------------------------------------------------------------------------------------------------------------

local function noop() end

local function loopInfo(seconds: number, style: Enum.EasingStyle, delay: number, reverses: boolean): TweenInfo
	return TweenInfo.new(seconds, style, Enum.EasingDirection.InOut, -1, reverses, delay)
end

-- Glow image transparency 0 <-> 0.4 over 2.4 s.
function Fx.breathe(glow: GuiObject, offset: number?): () -> ()
	local stop = noop
	safe("breathe", function()
		local label = glow :: ImageLabel
		label.ImageTransparency = 0
		if reduced() then
			return
		end
		local tween = TweenService:Create(
			label,
			loopInfo(1.2, Enum.EasingStyle.Sine, offset or 0, true),
			{ ImageTransparency = 0.4 }
		)
		tween:Play()
		stop = function()
			tween:Cancel()
			label.ImageTransparency = 0
		end
	end)
	return stop
end

-- Ambient diamond: opacity 0.15 -> 1, scale 0.5 -> 1.15, a quarter turn, 2.4 s ping-pong. Needs a UIScale child.
function Fx.twinkle(spark: GuiObject, offset: number?): () -> ()
	local stop = noop
	safe("twinkle", function()
		local frame = spark :: Frame
		local scale = scaleOf(spark)
		local rotation = frame.Rotation
		if reduced() then
			frame.BackgroundTransparency, scale.Scale = 0.4, 1
			return
		end
		frame.BackgroundTransparency, scale.Scale = 0.85, 0.5
		local info = loopInfo(1.2, Enum.EasingStyle.Sine, offset or 0, true)
		local fadeTween = TweenService:Create(frame, info, { BackgroundTransparency = 0, Rotation = rotation + 90 })
		local scaleTween = TweenService:Create(scale, info, { Scale = 1.15 })
		fadeTween:Play()
		scaleTween:Play()
		stop = function()
			fadeTween:Cancel()
			scaleTween:Cancel()
			frame.Rotation = rotation
		end
	end)
	return stop
end

-- Edge text: drifts up 260 px over 26 s on a linear loop.
function Fx.drift(label: GuiObject): () -> ()
	local stop = noop
	safe("drift", function()
		if reduced() then
			return
		end
		local start = label.Position
		local info = TweenInfo.new(26, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
		local tween = TweenService:Create(label, info, { Position = start - UDim2.fromOffset(0, 260) })
		tween:Play()
		stop = function()
			tween:Cancel()
			label.Position = start
		end
	end)
	return stop
end

------------------------------------------------------------------------------------------------------------------
-- Phase choreography (delays and durations in seconds, from the design)
------------------------------------------------------------------------------------------------------------------

function Fx.enterIntermission(p: IntermissionParts)
	safe("enterIntermission", function()
		Fx.slam(p.Card)
		if p.Countdown then
			Fx.slamRight(p.Countdown, 0.14)
		end
		Fx.slide(p.Tag, 0.22)
		Fx.rise(p.Title, 0.26)
		Fx.fade(p.Sub, 0.42)
	end)
end

function Fx.enterQuestion(p: QuestionParts)
	safe("enterQuestion", function()
		Fx.slam(p.Problem)
		Fx.slide(p.Tag, 0.18)
		Fx.rise(p.ProblemText, 0.14)
		Fx.pop(p.Seconds, 0.2)
		Fx.grow(p.TimerFill, 0.24)
		Fx.rise(p.InputRow, 0.28)
		Fx.pop(p.Submit, 0.38)
	end)
end

function Fx.enterReveal(p: RevealParts)
	safe("enterReveal", function()
		Fx.pulse(p.Problem, 1.04, 0.36)
		Fx.flash(p.ProblemFlash)
		Fx.flip(p.Answer, 0.08)
		for index, chip in p.Chips do
			Fx.slide(chip, 0.26 + (index - 1) * 0.07)
		end
	end)
end

function Fx.enterResults(p: ResultsParts)
	safe("enterResults", function()
		Fx.flyLeft(p.Pod3, 0)
		Fx.flyLeft(p.Pod2, 0.16)
		Fx.slam(p.Pod1, 0.36)
		Fx.flash(p.Pod1Flash, 0.72)
		for index, row in p.Rows do
			Fx.rowIn(row, 0.52 + (index - 1) * 0.06)
		end
	end)
end

-- A feedback toast appeared or changed. kind is a HudRules.ToastKind; delay is 0.52 when it arrives with Reveal.
function Fx.feedback(p: ToastParts, kind: string, delay: number?)
	safe("feedback", function()
		local d = delay or 0
		Fx.pop(p.Toast, d)
		if kind == "correct" then
			Fx.flash(p.ToastFlash, d + 0.12)
			Fx.burst(p.Sparks, d + 0.14)
		elseif kind == "sent" then
			if p.InputRow then
				Fx.pulse(p.InputRow, 1.04, 0.26, d)
			end
		else
			Fx.shake(p.Toast, d + 0.34)
		end
	end)
end

-- Once per whole second from the Heartbeat countdown. Never yields.
function Fx.secondTick(p: TickParts, phase: string, secondsLeft: number)
	safe("secondTick", function()
		if phase == "Question" and secondsLeft <= ALERT_SECONDS and secondsLeft > 0 then
			Fx.pulse(p.Seconds, ALERT_SCALE)
			Fx.shiver(p.Problem)
		elseif phase == "Question" then
			Fx.pulse(p.Seconds, TICK_SCALE, 0.26)
		elseif phase == "Intermission" then
			Fx.pop(p.CountNumber, 0, 0.38)
		end
	end)
end

-- The in-game REDUCED MOTION setting; GuiService.ReducedMotionEnabled always applies on top of it.
function Fx.setReducedMotion(on: boolean)
	reducedOverride = on == true
end

function Fx.reducedMotion(): boolean
	return reduced()
end

-- Cancels every running tween (Hud stop).
function Fx.destroy()
	safe("destroy", function()
		for _, bySlot in slots do
			for _, slot in bySlot do
				for _, tween in slot.tweens do
					tween:Cancel()
				end
				table.clear(slot.tweens)
				slot.token = -1
			end
		end
	end)
end

return table.freeze(Fx)
