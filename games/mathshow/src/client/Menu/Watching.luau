--!strict
-- The WATCHING banner (TASK-0100, screen 10): "WATCHING · YOU JOIN NEXT MATCH", drawn over the HUD for a player who pressed
-- JOIN SHOW while a match was already under way. Hud tells it when to show (Hud.setWatchingListener). Cosmetic: every fault
-- warns and leaves the HUD alone.

local Players = game:GetService("Players")

local View = require(script.Parent.View)

local Watching = {}

local view: View.View? = nil

local function noop() end

function Watching.start()
	if view then
		return
	end
	local ok, err = pcall(function()
		local handlers: View.Handlers = {
			go = noop,
			back = noop,
			locked = function(_what: string) end,
			join = noop,
			setting = function(_key: string, _value: number | boolean) end,
		}
		local built = View.build(Players.LocalPlayer:WaitForChild("PlayerGui"), handlers, {
			overlay = true,
			name = "MathShowWatching",
			displayOrder = 5, -- above the HUD (0), below the menu (10)
		})
		built.gui.Enabled = false
		view = built
	end)
	if not ok then
		warn(`[MathShow] Watching banner failed to build: {err}`)
	end
end

function Watching.set(on: boolean)
	local v = view
	if not v then
		return
	end
	local ok, err = pcall(function()
		if on then
			v.render("watching", {})
		end
		v.gui.Enabled = on
	end)
	if not ok then
		warn(`[MathShow] Watching banner update failed: {err}`)
	end
end

return Watching
