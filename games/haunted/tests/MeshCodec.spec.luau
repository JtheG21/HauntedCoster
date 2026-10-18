--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MeshCodec = require(ReplicatedStorage.Shared.Art.MeshCodec)

-- Produced by games/haunted/art/hcart/codec.py from the same quad as tests/test_hcm_codec.py.
local FIXTURE =
	"SENNMQQAAAACAAAAAQAAAAAAAAAAAADAvwAAAEAAAEBAAADAPwAAAAD/////AAD//////////wAA//8AAICA////gID//wAAAP8AAAD/ChQeAAAAAIABAAAAAQACwP+AAAAAAQACAAAAAgADAA=="

return function(t: TestRunner.T)
	local function near(a: Vector3, b: Vector3, eps: number): boolean
		return (a - b).Magnitude < eps
	end

	t.test("decodes counts, bounds and 1-based faces", function()
		local m = MeshCodec.decode(FIXTURE)
		t.eq(#m.positions, 4)
		t.eq(#m.faces, 2)
		t.eq(m.faces[2][3], 4)
		t.truthy(near(m.min, Vector3.new(0, 0, -1.5), 1e-4), "min")
		t.truthy(near(m.size, Vector3.new(2, 3, 1.5), 1e-4), "size")
		t.truthy(near(m.centre, Vector3.new(1, 1.5, -0.75), 1e-4), "centre")
	end)

	t.test("positions, normals, colours and uvs survive quantisation", function()
		local m = MeshCodec.decode(FIXTURE)
		t.truthy(near(m.positions[3], Vector3.new(2, 3, 0), 1e-3), "position")
		t.truthy(near(m.positions[4], Vector3.new(0, 3, -1.5), 1e-3), "position 4")
		t.truthy(near(m.normals[2], Vector3.new(0, 0, -1), 0.02), "normal -Z")
		t.truthy(near(m.normals[3], Vector3.new(1, 0, 0), 0.02), "normal +X")
		t.eq(math.round(m.colors[1].R * 255), 255)
		t.eq(math.round(m.colors[4].B * 255), 30)
		local uvs = m.uvs :: { Vector2 }
		t.truthy(uvs ~= nil, "has uvs")
		t.eq(uvs[2].X, 1.5)
		t.eq(uvs[4].X, -0.25)
	end)

	t.test("rejects text that is not HCM1", function()
		t.truthy(not pcall(MeshCodec.decode, "QUJDRA=="), "bad magic")
	end)
end
