--!strict
-- Tunable values for the collectible prototype (T-001).

local CollectibleConfig = table.freeze({
	Count = 10,
	CoinValue = 1,
	RespawnSeconds = 5,
	-- Max distance (studs) from the HumanoidRootPart to the coin's center for a touch to count.
	MaxPickupDistance = 12,
	SpawnCenter = Vector3.new(0, 2, 0),
	SpawnRadius = 30,
	FolderName = "Collectibles",
})

return CollectibleConfig
