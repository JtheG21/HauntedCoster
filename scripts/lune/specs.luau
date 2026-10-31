--!strict
-- Headless unit specs: `lune run scripts/lune/specs` (from the repo root) runs the active game named in
-- scripts/active-game.env; check.sh runs it. `lune run scripts/lune/specs archive` runs ARCHIVED instead.
--
-- Studio-free twin of each game's tests/TestRunner.luau. For each game it rebuilds the slice of the
-- Rojo tree the specs touch (ReplicatedStorage.Shared and TestService.Tests, as mapped in that game's
-- project file) as fake instances backed by files, then loads every module with its own `script`,
-- `game` and `require`, so the source keeps Roblox's instance requires unchanged. Vector3/Color3/CFrame
-- come from @lune/roblox. Anything else Roblox-only (services, real Instances, task, physics) is absent
-- on purpose: a spec that needs it belongs in a Studio Play scenario, and fails loudly here.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox") :: any

local env: { [string]: string } = {}
for line in fs.readFile("scripts/active-game.env"):gmatch("[^\n]+") do
	local key, value = line:match("^([%w_]+)=(.*)$")
	if key and value then
		env[key] = value
	end
end
local ARCHIVED = {
	{
		dataModel = "HauntedCollector",
		shared = "archive/GAME-002-haunted-collector/src/shared",
		tests = "archive/GAME-002-haunted-collector/tests",
	},
}
local GAMES = if process.args[1] == "archive"
	then ARCHIVED
	else {
		{
			dataModel = env.ACTIVE_GAME_NAME,
			shared = `{env.ACTIVE_GAME_ROOT}/src/shared`,
			tests = `{env.ACTIVE_GAME_ROOT}/tests`,
		},
	}
local SKIP_DIRS = { scenarios = true } -- Play scenarios need a running server

type Node = {
	Name: string,
	ClassName: string,
	Parent: Node?,
	Value: string?,
	_path: string?,
	_children: { [string]: Node },
}

local nodeMethods = {}
local nodeMeta = {}

local function newNode(name: string, className: string, parent: Node?, path: string?): Node
	local node = setmetatable({
		Name = name,
		ClassName = className,
		Parent = parent,
		_path = path,
		_children = {},
	}, nodeMeta) :: any
	if parent then
		parent._children[name] = node
	end
	return node
end

function nodeMethods.IsA(self: Node, className: string): boolean
	return self.ClassName == className
end

function nodeMethods.FindFirstChild(self: Node, name: string): Node?
	return self._children[name]
end

function nodeMethods.WaitForChild(self: Node, name: string): Node
	return self._children[name] or error(`{name} is not a child of {self.Name} (headless tree)`, 2)
end

function nodeMethods.GetChildren(self: Node): { Node }
	local list = {}
	for _, child in self._children do
		table.insert(list, child)
	end
	table.sort(list, function(a, b)
		return a.Name < b.Name
	end)
	return list
end

function nodeMethods.GetFullName(self: Node): string
	return if self.Parent and self.Parent.ClassName ~= "DataModel"
		then `{nodeMethods.GetFullName(self.Parent)}.{self.Name}`
		else self.Name
end

nodeMeta.__index = function(self: Node, key: string): any
	local method = (nodeMethods :: any)[key]
	if method then
		return method
	end
	local child = rawget(self :: any, "_children")[key]
	if child then
		return child
	end
	error(`{key} is not a valid member of {nodeMethods.GetFullName(self)} (headless tree)`, 2)
end
nodeMeta.__tostring = function(self: Node): string
	return self.Name
end

-- Mirror Rojo's file rules for the subset GAME-002 uses: dirs → Folder, *.luau → ModuleScript,
-- *.txt → StringValue. (No init.luau or *.server/*.client scripts live under the mounted paths.)
local function mount(parent: Node, dir: string)
	for _, entry in fs.readDir(dir) do
		local path = `{dir}/{entry}`
		if fs.isDir(path) then
			if not SKIP_DIRS[entry] then
				mount(newNode(entry, "Folder", parent, nil), path)
			end
		elseif entry:match("%.luau$") then
			newNode((entry:gsub("%.luau$", "")), "ModuleScript", parent, path)
		elseif entry:match("%.txt$") then
			local node = newNode((entry:gsub("%.txt$", "")), "StringValue", parent, path)
			node.Value = fs.readFile(path)
		end
	end
end

local game: Node = nil :: any -- reassigned per game below; requireNode reads it at call time
function nodeMethods.GetService(self: Node, name: string): Node
	return self._children[name] or error(`service {name} is not available headlessly`, 2)
end

-- Seeded stand-in for Roblox's Random (xorshift32). Same API for what GAME-002 uses, but a different
-- sequence from Roblox's PCG, so specs must assert properties (ranges, rates), never exact seeded values.
local Random = {}
Random.__index = Random

function Random.new(seed: number?)
	local s = bit32.band(math.floor(seed or os.clock() * 1e6), 0xFFFFFFFF)
	local self = setmetatable({ _s = if s == 0 then 0x9E3779B9 else s }, Random)
	for _ = 1, 4 do -- decorrelate small seeds
		self:_next()
	end
	return self
end

function Random._next(self: any): number
	local x = self._s
	x = bit32.bxor(x, bit32.lshift(x, 13))
	x = bit32.bxor(x, bit32.rshift(x, 17))
	x = bit32.bxor(x, bit32.lshift(x, 5))
	self._s = x
	return x
end

function Random.NextNumber(self: any, min: number?, max: number?): number
	local lo, hi = min or 0, max or 1
	return lo + (self:_next() / 4294967296) * (hi - lo)
end

function Random.NextInteger(self: any, min: number, max: number): number
	return min + self:_next() % (max - min + 1)
end

local cache: { [Node]: any } = {}
local loading: { [Node]: boolean } = {}

local function requireNode(node: Node): any
	if type(node) ~= "table" or getmetatable(node :: any) ~= nodeMeta or node.ClassName ~= "ModuleScript" then
		error(`headless require expects a ModuleScript, got {tostring(node)}`, 2)
	end
	if cache[node] ~= nil then
		return cache[node]
	end
	if loading[node] then
		error(`cyclic require of {nodeMethods.GetFullName(node)}`, 2)
	end
	loading[node] = true
	local chunk = luau.load(fs.readFile(node._path :: string), {
		debugName = node._path,
		environment = {
			script = node,
			game = game,
			require = requireNode,
			Vector3 = roblox.Vector3,
			Vector2 = roblox.Vector2,
			Color3 = roblox.Color3,
			CFrame = roblox.CFrame,
			NumberRange = roblox.NumberRange,
			Random = Random,
		},
	})
	local result = chunk()
	loading[node] = nil
	cache[node] = result
	return result
end

-- Same contract as TestRunner.T.
local totalPassed, totalFailed = 0, 0
for _, g in GAMES do
	if not (fs.isDir(g.shared) and fs.isDir(g.tests)) then
		print(`[lune specs] skipping {g.dataModel}: {g.shared} or {g.tests} not found`)
		continue
	end

	game = newNode(g.dataModel, "DataModel", nil, nil)
	mount(newNode("Shared", "Folder", newNode("ReplicatedStorage", "ReplicatedStorage", game, nil), nil), g.shared)
	local testsFolder = newNode("Tests", "Folder", newNode("TestService", "TestService", game, nil), nil)
	mount(testsFolder, g.tests)

	local passed, failed = 0, 0
	for _, child in nodeMethods.GetChildren(testsFolder) do
		if child.ClassName == "ModuleScript" and child.Name:match("%.spec$") then
			local t = {
				test = function(name: string, fn: () -> ())
					local ok, err = pcall(fn)
					if ok then
						passed += 1
					else
						failed += 1
						print(`FAIL {g.dataModel} {child.Name} > {name}: {err}`)
					end
				end,
				eq = function(actual: any, expected: any, msg: string?)
					if actual ~= expected then
						error(`{msg or "eq"}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
					end
				end,
				truthy = function(value: any, msg: string?)
					if not value then
						error(msg or "expected truthy value", 2)
					end
				end,
			}
			local ok, err = pcall(function()
				requireNode(child)(t)
			end)
			if not ok then
				failed += 1
				print(`FAIL {g.dataModel} {child.Name} (load): {err}`)
			end
		end
	end
	print(`[lune specs] {g.dataModel}: {passed} passed, {failed} failed`)
	totalPassed += passed
	totalFailed += failed
end

print(`[lune specs] {totalPassed} passed, {totalFailed} failed`)
process.exit(if totalFailed == 0 and totalPassed > 0 then 0 else 1)
