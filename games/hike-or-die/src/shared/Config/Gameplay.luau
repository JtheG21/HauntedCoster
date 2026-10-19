--!strict
local Gameplay = {
	MaxPhotoRange = 72,
	MinShutterInterval = 0.65,
	MaxAimFacingDot = 0.05,
	MaxAimOriginOffset = 1.25,
	SelfieForwardOffset = 3.4,
	SelfieSideOffset = 2.4,
	SelfieHeightOffset = 1.2,
	ExtractDistance = 12,
	ProvokeDistance = 48,
	ProvokeCooldown = 3,
	InvestigationSeconds = 9,
	LostSightGrace = 2.5,
	MaxPursuitSeconds = 12,
	CatchDistance = 5,
	CatchGraceSeconds = 1.5,
	WalkSpeed = 16,
	Evidence = {
		CloseRange = 12,
		GoodRange = 30,
		LongRange = 55,
		TightFrameDegrees = 4,
		ClearFrameDegrees = 12,
	},
	RoamPoints = {
		Vector3.new(-18, 8, 8),
		Vector3.new(18, 8, 8),
		Vector3.new(0, 8, -25),
		Vector3.new(0, 8, 25),
	},
	CryptidSpawnPoints = {
		Vector3.new(0, 8, 0),
		Vector3.new(-16, 8, -4),
		Vector3.new(16, 8, -4),
	},
}
return table.freeze(Gameplay)
