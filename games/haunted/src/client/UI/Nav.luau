--!strict
-- Screen navigation (TASK-0048): one menu open at a time, one close/back behaviour everywhere (the X button,
-- Escape or the controller's B), and controller focus that lands inside the opened screen and returns to the
-- HUD dock when it closes. Screens register open/close/isOpen and an optional root to select into.

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Nav = {}

export type Screen = {
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	root: (() -> GuiObject?)?,
	back: (() -> boolean)?, -- handles an inner "back" (e.g. details -> catalog); true when it consumed it
}

local screens: { [string]: Screen } = {}
local order: { string } = {}
local dock: GuiObject? = nil

function Nav.register(name: string, screen: Screen)
	screens[name] = screen
	table.insert(order, name)
end

function Nav.setDock(obj: GuiObject)
	dock = obj
end

local function firstSelectable(root: GuiObject): GuiObject?
	for _, d in root:GetDescendants() do
		if d:IsA("GuiButton") and d.Visible and d.Selectable and d.Active then
			return d
		end
	end
	return nil
end

function Nav.current(): string?
	for _, name in order do
		if screens[name].isOpen() then
			return name
		end
	end
	return nil
end

function Nav.closeAll(except: string?)
	for name, s in screens do
		if name ~= except and s.isOpen() then
			s.close()
		end
	end
end

function Nav.open(name: string)
	local s = screens[name]
	if not s then
		return
	end
	Nav.closeAll(name)
	if not s.isOpen() then
		s.open()
	end
	if UserInputService.GamepadEnabled and s.root then
		local r = s.root()
		local first = r and firstSelectable(r)
		if first then
			GuiService.SelectedObject = first
		end
	end
end

function Nav.toggle(name: string)
	local s = screens[name]
	if s and s.isOpen() then
		s.close()
		Nav.restoreFocus()
	else
		Nav.open(name)
	end
end

function Nav.restoreFocus()
	if UserInputService.GamepadEnabled and GuiService.SelectedObject then
		GuiService.SelectedObject = if dock then firstSelectable(dock) else nil
	end
end

-- Back: an inner step first (details -> list), otherwise close the open screen.
function Nav.back(): boolean
	local name = Nav.current()
	if not name then
		return false
	end
	local s = screens[name]
	if s.back and s.back() then
		return true
	end
	s.close()
	Nav.restoreFocus()
	return true
end

local started = false
function Nav.start()
	if started then
		return
	end
	started = true
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.ButtonB or (input.KeyCode == Enum.KeyCode.Escape and not processed) then
			Nav.back()
		end
	end)
end

return Nav
