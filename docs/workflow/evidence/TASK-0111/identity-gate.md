# TASK-0106 identity gate, completed by TASK-0111 (2026-10-30)
Fresh Play, stamp `9b1a2d0+dirty 2026-10-31T06:08:29Z`: `main` plus this task's uncommitted changes. Each run: 109 rows, `no_profile=0`.

| Viewport | Scale | Failed | Rows |
|---|---|---|---|
| 844x390 | 1 | 1 | "FIRST CORRECT" 5 |
| 1920x1080 | 2.2749 | 2 | "FIRST CORRECT" 4.75, "[WWWWW]" 5.75 |
| 812x375 | 0.9615 | 2 | "FIRST CORRECT" 5, "[WWWWW]" 5.75 |

Numbers are the largest passing margin, in 0.25 px steps, against the 6 px rule.

- **"FIRST CORRECT"** on `shard-id-status-gold`, chip 122x32: a real shortfall of about 1 px, near the slanted lower-right edge. Not fixed.
- **"[WWWWW]"** on `shard-id-tag`: a stress fixture. It sits at exactly 6 px at scale 1 and loses a quarter pixel to scale rounding.

The harness previously measured text from the label's top-left corner. That hid the "FIRST CORRECT" shortfall and falsely failed the centred "+120 XP", "STREAK" and "MVP" chips once profiles existed. It now applies text alignment, as `tests/studio/TextFit` does.

**Generator check:** `scripts/shape_profiles.py` reproduced all 59 existing rows exactly before adding 22 `shard-id-*` rows.

**Screenshot:** `identity-boards-844x390.jpg` shows the harness canvas at scale 1. The boards overlap each other and use flat placeholders, with some text mid-fade, so it doesn't support a visual comparison with S1-S7. That comparison needs the uploaded PNGs and a jg review.
