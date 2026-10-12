--!strict
-- Habitat module contract (TASK-0026, ADR-0007): the Ghost Cemetery fits the shared footprint and gates,
-- and the validator catches a module that breaks the contract.
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local World = require(Shared.Config.World)
local Habitats = require(Shared.Config.Habitats)
local HabitatRules = require(Shared.Rules.HabitatRules)

return function(t: TestRunner.T)
	t.test("the Ghost Cemetery fits the module contract", function()
		local problems = HabitatRules.validate(Habitats.Cemetery)
		t.eq(#problems, 0, table.concat(problems, "; "))
	end)

	t.test("every gate leads in: each cemetery gate path starts at its gate", function()
		for gate, id in Habitats.Cemetery.gatePaths do
			local first: Vector3? = nil
			for _, path in Habitats.Cemetery.paths do
				if path.id == id then
					first = path.points[1]
				end
			end
			t.truthy(first ~= nil, `gate {gate}`)
			local inner = World.gatePoint(gate, World.Hub.moduleRadius)
			t.truthy(((first :: Vector3) - inner).Magnitude < 4, `gate {gate} path starts at the gate`)
		end
	end)

	t.test("the Weeping Angel and Bell Tower are the cemetery's landmarks", function()
		t.truthy(Habitats.landmarkById("Angel") ~= nil)
		t.truthy(Habitats.landmarkById("BellTower") ~= nil)
	end)

	t.test("the validator rejects a module that breaks the contract", function()
		local broken = table.clone(Habitats.Cemetery)
		broken.id = "Broken"
		broken.zones = {
			{
				id = "Outside",
				name = "Outside",
				rect = { x1 = 100, x2 = 140, z1 = 0, z2 = 20 }, -- past the footprint
				dark = false,
				gated = false,
				maxMonsters = 1,
				spawns = { Wisp = 1 },
			},
			{
				id = "Blocking",
				name = "Blocking",
				rect = { x1 = -6, x2 = 6, z1 = 96, z2 = 104 }, -- in the south gate corridor
				dark = false,
				gated = false,
				maxMonsters = 1,
				spawns = { Wisp = 1 },
			},
		}
		broken.landmarks = { { id = "Lonely", name = "Lonely", zone = "Outside", position = Vector3.new(0, 0, 0) } }
		broken.gatePaths = { "SouthPath" }
		broken.starter = nil
		local problems = table.concat(HabitatRules.validate(broken), "\n")
		for _, expected in { "leaves the footprint", "gate corridor", "at least two landmarks", "one gate path" } do
			t.truthy(string.find(problems, expected, 1, true) ~= nil, expected)
		end
	end)

	t.test("path clearance and gate corridors", function()
		t.truthy(HabitatRules.pathClearance(Habitats.Cemetery, 0, 112) < 0, "on the south path")
		t.truthy(HabitatRules.inGateCorridor(0, 105), "inside the south gate")
		t.truthy(not HabitatRules.inGateCorridor(0, 60), "well inside the hub")
		t.truthy(not HabitatRules.inGateCorridor(0, 130), "outside the wall")
	end)
end
