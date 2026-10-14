---
id: LES-0007
title: Blender Studio Scale
type: lesson
status: done
created: 2026-10-12
updated: 2026-10-12
tags:
  - lesson/pipeline
related:
  - "[[Blender Pipeline]]"
---
# LES-0007: Blender to Studio keeps exact scale and orientation with the documented settings

## Evidence (2026-10-12)
- **Export:** `scripts/blender/export_for_roblox.py` settings, from Blender 5.1.0 with Unit System None. The test scene is `~/Roblox-Work/blender-scale-test/make_scale_test.py`: a 4-unit cube, plus a 1-unit marker 3 units toward −Y.
- **Import:** jg imported the FBX and the glb into Place1 (World Forward Front, World Up Top, Scale Unit Stud). Claude read the parts back through Studio MCP:

| File | Cube size | Marker size | Marker offset from cube | Hierarchy |
|---|---|---|---|---|
| FBX | 4.00 × 4.00 × 4.00 | 1.00 × 1.00 × 1.00 | −3.00 Z, −1.50 Y | `Model ScaleTest` > MeshParts named after the **objects** |
| glb | 4.00 × 4.00 × 4.00 | 1.00 × 1.00 × 1.00 | −3.00 Z, −1.50 Y | `Scene` > one Model per object > a MeshPart named after the **mesh data** (`Cube`, `Cube.001`) |

## Lesson
- **Scale:** 1 Blender unit is exactly 1 stud in both formats.
- **Orientation:** Blender −Y becomes Studio −Z (the front, the LookVector direction). Bases stay aligned: the −1.50 Y offset equals the difference in half-heights.
- **Placement:** both imports landed at the insertion point, not the Blender origin. "Insert Using Scene Position" was off. Turn it on when the placement matters.
- **Format:** **FBX is the default.** It gives flat, object-named MeshParts in one Model. glb is equally accurate, but wraps each object in an extra Model and uses the mesh data names. To use glb, rename the mesh data to match the objects first.
