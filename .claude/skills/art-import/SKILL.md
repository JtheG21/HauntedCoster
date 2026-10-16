---
name: art-import
description: Import a baked Haunted Collector art asset into Studio and keep it in the repo. Covers the 3D Importer upload (jg's approval each time), filing the parts under ServerStorage.ImportedArt, saving ImportedArt.rbxm into Rojo source, and the round-trip check. Use after an art revision passes review.sh and jg wants the textured version in game.
argument-hint: <asset>
---
# Import $ARGUMENTS into the game

Proven on the Lantern Wisp (TASK-0043 rev 1, 2026-10-16). Notes win over this list: [[SYS-Haunted-Art-Direction]] (budgets, asset IDs, the Meshy credit), AGENTS.md (approval gates, one Studio user at a time).

## 0. Gates
- **The upload goes to jg's account and needs jg's approval in chat for this import.** An earlier approval doesn't carry over to a new asset or revision.
- Run `games/haunted/art/tools/review.sh $ARGUMENTS --glb` first and show jg the sheets. Budget: OK, or a decision recorded.
- Run the `studio-preflight` skill. If Rojo belongs to another session, work in a separately built test place (`rojo build haunted.project.json -o ~/Roblox-Work/haunted/<Name>.rbxl`) and don't connect Rojo.

## 1. Upload with the 3D Importer (computer use)
1. `request_access` for RobloxStudio. If the background screenshot fails, use the full-screen batch tools.
2. In the Import Queue panel: folder icon → pick `~/Roblox-Work/haunted/art/fbx/$ARGUMENTS.glb` → Import Preview. Name it after the asset and revision (e.g. `Wisp8k`). Keep "Upload to Roblox" on → **Import**.
3. Watch the queue status. **"Import Failed" with no reason is common on the first try: select the row and Start Import once more.** If it fails twice, stop and report. Check the maps are ≤ 1024 px (Roblox's image limit) before retrying.
4. `app_release` / `release_full_control` when done.

## 2. File the parts (Studio MCP, Edit)
Identify the window by place file (`execute_luau`: `return game.Name`); every window reports as "Game". Then, for each baked part name, move the new MeshPart into `ServerStorage.ImportedArt.<asset>`: copy `Anchored, CanCollide, CanTouch, CanQuery, CastShadow, Material, Color, Massless` and the attributes from the previous part, if there was one, then set `CollisionFidelity = Box`, `RenderFidelity = Automatic`, `CFrame = CFrame.new()`, and destroy the imported model. LampGlow-style Neon parts stay on the in-game build. Record the new mesh and map IDs from `MeshId` and the `SurfaceAppearance` maps.

## 3. Check in Play
Start Play, then on the Client count parts with the `Imported` attribute on the asset's models, and confirm `@lod1` twins beyond `LodDistance`. Pin the camera with `RunService:BindToRenderStep` (the game's camera overrides `CurrentCamera` each frame), take a close-up and show jg.

## 4. Save into the repo
1. `python3 -I scripts/studio_transfer.py receive <scratch>/ImportedArt.rbxm` (run in the background; one request, then it exits).
2. In Edit:
   ```lua
   local H = game:GetService("HttpService"); local was = H.HttpEnabled
   local b = game:GetService("SerializationService"):SerializeInstancesAsync({ game.ServerStorage.ImportedArt })
   local hex = table.create(buffer.len(b))
   for i = 0, buffer.len(b) - 1 do hex[i + 1] = string.format("%02x", buffer.readu8(b, i)) end
   local ok, r = pcall(function() H.HttpEnabled = true; return H:PostAsync("http://127.0.0.1:8765/", table.concat(hex), Enum.HttpContentType.TextPlain) end)
   pcall(function() H.HttpEnabled = was end)
   return tostring(ok) .. " " .. tostring(r)
   ```
   HttpEnabled is only on for that call, and is restored.
3. Copy the file to `games/haunted/assets/ImportedArt.rbxm` (mapped to `ServerStorage.ImportedArt` in `haunted.project.json`).
4. Round trip: `rojo build` to scratch, extract `ServerStorage.ImportedArt` with Lune (`roblox.deserializePlace` → `serializeModel`), `studio_transfer.py serve` it, and in Studio `GetAsync` + `DeserializeInstancesAsync`. Compare MeshId, ColorMap, NormalMap, Size and RenderFidelity with the live parts. All must match.

## 5. Record
Update the asset IDs and triangle counts in [[SYS-Haunted-Art-Direction]], and the task note's implementation record. Third-party base meshes need their credit recorded (and a player-facing credit before publish). Commit on the task branch, with the preflight chained.
