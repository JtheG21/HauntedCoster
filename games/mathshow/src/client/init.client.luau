--!strict
-- GAME-004 MathShow: client entry point.

local Hud = require(script.Hud)
local Menu = require(script.Menu)

Hud.start()
-- The menu opens first. The match loop already runs for every player, so JOIN SHOW only reveals the HUD (no server
-- change, no new remote).
Hud.setVisible(false)
Menu.start({
	onJoin = function()
		Hud.setVisible(true)
	end,
})
print("[MathShow] client ready")
