--!strict
-- Rare capture finisher (TASK-0054): a 12.5 s cosmetic sequence played through SequencePlayer (ADR-0012).
-- Client-side only; the runner undoes every cue, so the camera, input and lighting return to normal on
-- finish, cancel or error. Call preload() once before the first run so the meshes are ready (creating a
-- MeshPart yields, which a running sequence must not do); an asset that fails to load is skipped.
--
--   RareCaptureFinisher.preload()
--   local run = RareCaptureFinisher.play(monsterPart, { destination = lanternPosition })
--   run:stop() -- cancels early; onDone still fires

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Finisher = require(ReplicatedStorage.Shared.Config.RareCaptureFinisher)
local CameraRig = require(script.Parent.Finisher.CameraRig)
local Effects = require(script.Parent.Finisher.Effects)
local Meshes = require(script.Parent.Finisher.Meshes)
local SequencePlayer = require(script.Parent.SequencePlayer)

local RareCaptureFinisher = {}

export type Options = {
	reduced: boolean?, -- weaker flashes, shake, particle rates and field-of-view swing
	destination: Vector3?, -- where the orb finally lands (defaults to a point in front of the monster)
	onDone: (() -> ())?,
}

local DEFAULT_DESTINATION_OFFSET = Vector3.new(0, 1.5, 12)

function RareCaptureFinisher.preload()
	Meshes.preload()
end

-- Builds the finisher around `target` (the captured monster) without starting it: call :play() to run
-- it from Heartbeat or :step(dt) to drive it by hand. :stop() cancels and cleans up.
function RareCaptureFinisher.new(target: BasePart, opts: Options?): SequencePlayer.Player
	local o: Options = opts or {}
	local reduced = o.reduced == true

	local fx = Instance.new("Folder")
	fx.Name = "FinisherFx"
	fx.Parent = Workspace
	local anchor = Instance.new("Part")
	anchor.Name = "FinisherAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = target.Position
	anchor.Parent = fx

	local handlers: SequencePlayer.Handlers = {
		camera = CameraRig.new(target, reduced),
		effect = Effects.new({
			fx = fx,
			anchor = anchor,
			target = target,
			destination = o.destination or (target.Position + DEFAULT_DESTINATION_OFFSET),
			reduced = reduced,
		}),
	}
	return SequencePlayer.new(Finisher, handlers, function()
		fx:Destroy()
		if o.onDone then
			o.onDone()
		end
	end)
end

function RareCaptureFinisher.play(target: BasePart, opts: Options?): SequencePlayer.Player
	local player = RareCaptureFinisher.new(target, opts)
	player:play()
	return player
end

return RareCaptureFinisher
