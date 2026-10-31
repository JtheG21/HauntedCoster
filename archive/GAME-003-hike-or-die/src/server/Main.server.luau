--!strict
local Workspace = game:GetService("Workspace")

-- Requiring the generated builder installs the map emitted from map/hike-trail.json.
require(script.Parent.World.TrailMapGenerated)
assert(Workspace:FindFirstChild("HikeOrDieTrail"), "Generated Gate 1 trail did not build")

local RoundService = require(script.Parent.RoundService)
local EvidenceService = require(script.Parent.EvidenceService)

RoundService.start()
EvidenceService.start()

print("[HikeOrDie] Gate 1 local prototype ready")
