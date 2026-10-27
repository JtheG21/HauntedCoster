--!strict
-- GAME-004 MathShow: client entry point.

local Hud = require(script.Hud)
local Menu = require(script.Menu)
local Watching = require(script.Menu.Watching)

Hud.start()
-- The menu opens first. JOIN SHOW tells the server (JoinShow remote; it decides who is in the match) and reveals the HUD;
-- a player who joins mid-match sees the WATCHING banner (Hud tells Watching) until the next match.
Hud.setVisible(false)
Watching.start()
Hud.setWatchingListener(Watching.set)
Menu.start({
	onJoin = function()
		Hud.setVisible(true)
	end,
})
print("[MathShow] client ready")
