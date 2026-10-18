--!strict
-- Client player for the sequence runner (ADR-0012). Maps the pure runner's start/stop actions onto
-- handlers, steps them from one Heartbeat clock, and always runs every stop on finish or cancel.
-- Cosmetic only: nothing here grants, validates or changes gameplay state.

local RunService = game:GetService("RunService")

local Sequence = require(game:GetService("ReplicatedStorage").Shared.Sequence)

local SequencePlayer = {}
SequencePlayer.__index = SequencePlayer

-- A handler starts a cue and returns a function that undoes it (or nil for fire-and-forget).
export type Handler = (cue: Sequence.Cue) -> (() -> ())?
export type Handlers = { [string]: Handler }
export type Player = typeof(setmetatable(
	{} :: {
		runner: Sequence.Runner,
		handlers: Handlers,
		undo: { [string]: () -> () },
		conn: RBXScriptConnection?,
		onDone: (() -> ())?,
	},
	SequencePlayer
))

function SequencePlayer.new(def: Sequence.Def, handlers: Handlers, onDone: (() -> ())?): Player
	return setmetatable(
		{ runner = Sequence.newRunner(def), handlers = handlers, undo = {}, conn = nil, onDone = onDone },
		SequencePlayer
	)
end

local function apply(self: Player, actions: { Sequence.Action })
	for _, a in actions do
		if a.op == "start" then
			local handler = self.handlers[a.cue.kind]
			if handler then
				local ok, undo = pcall(handler, a.cue)
				if ok and undo then
					self.undo[a.cue.id] = undo
				elseif not ok then
					warn(`SequencePlayer: cue {a.cue.id} failed: {undo}`)
				end
			end
		else
			local undo = self.undo[a.cue.id]
			self.undo[a.cue.id] = nil
			if undo then
				local ok, err = pcall(undo :: any)
				if not ok then
					warn(`SequencePlayer: cleanup of cue {a.cue.id} failed: {err}`)
				end
			end
		end
	end
end

-- Advance by dt seconds. Exposed so a test can drive the clock without Heartbeat.
function SequencePlayer.step(self: Player, dt: number)
	apply(self, self.runner:advance(dt))
	if self.runner:isDone() then
		self:stop()
	end
end

function SequencePlayer.play(self: Player)
	if self.conn then
		return
	end
	self.conn = RunService.Heartbeat:Connect(function(dt)
		self:step(dt)
	end)
end

-- Disconnects the clock and runs cleanup for anything still active. Safe to call twice.
function SequencePlayer.stop(self: Player)
	if self.conn then
		self.conn:Disconnect()
		self.conn = nil
	end
	apply(self, self.runner:cancel())
	local onDone = self.onDone
	self.onDone = nil
	if onDone then
		task.spawn(onDone)
	end
end

return SequencePlayer
