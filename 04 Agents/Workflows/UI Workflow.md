---
id: AGENT-WF-UI
title: UI Workflow
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/production
related:
  - "[[Task Intake]]"
  - "[[UI References]]"
---
# UI and graphic design

## Gather
- **User goals:** what the player is trying to do on this screen, and the flow in and out (open, act, confirm, close).
- **References:** `10 References/01 UI/` ([[UI References]]) and SODT's `src/menu/` patterns ([[SODT-RC-1]]).
- **The project's UI kit:** GAME-002 uses `games/haunted/src/client/UI/Theme.luau` for colours, fonts and constructors. Extend it rather than styling inline.

## Decide
- **Information hierarchy:** one primary action per screen. Secondary information is dimmer or smaller.
- **Layout:** use `Scale` for position and size with `UIAspectRatioConstraint` or `UISizeConstraint` limits. Account for the top-bar inset (`GuiService:GetGuiInset()`) and phone notches.
- **Typography, spacing, iconography:** from the kit. New tokens go into the kit, not into one screen.
- **States:** for every control, decide normal, hover, pressed, disabled, loading, empty and error, plus the transitions between them.
- **Input:** mouse, touch and gamepad. Touch targets need to be large enough for a thumb, and gamepad needs a selection path.
- **Accessibility:**
  - Text contrast against its panel.
  - Never colour as the only signal.
  - Readable text size on a phone.
  - Motion that doesn't block input.
- **Mockups (optional):** Claude Design or Figma for exploration (see [[Task Intake]] for availability). Implementation follows the kit, not the mockup's pixels.

## Build
- **Client-only presentation:** the UI reads replicated state and sends requests; the server validates them ([[Systems Workflow]]).
- One module per screen, mounted from the client entry point. Follow the existing pattern (GAME-002: `UI/*.luau` with `mount(gui, ...)`).

## Acceptance
- Screenshots at desktop size and at a phone-sized viewport (Studio's device emulator is a manual step). Nothing is clipped or overlapping, and the primary action is visible.
- Each state is shown once, including error and empty.
- Keyboard and gamepad paths work where the game supports them.
- `design:accessibility-review` can audit a screenshot when contrast is in doubt.
- Look and feel is jg's manual check.
- On-device checks wait until the game is nearly finished (jg, 2026-10-12).
