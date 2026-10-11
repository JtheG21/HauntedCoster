--!strict
-- Ghost-train route limits and ride tuning.

local Track = {
	MinPoints = 4,
	MaxPoints = 16,
	MinLength = 60,
	MaxLength = 320,
	MinPointSpacing = 6,
	SampleSpacing = 3, -- studs between sampled points along the spline
	RideSpeed = 14, -- studs/s
	RailHeight = 1.4,
	QualityMin = 0.9,
	QualityMax = 1.25,
	MaxPieces = 3,
	Pieces = {
		ScareArch = { label = "Scare Arch", quality = 0.06 },
		FogTunnel = { label = "Fog Tunnel", quality = 0.05 },
	} :: { [string]: { label: string, quality: number } },
	PieceOrder = { "ScareArch", "FogTunnel" },
}

return table.freeze(Track)
