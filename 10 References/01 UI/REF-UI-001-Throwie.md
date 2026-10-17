---
id: REF-UI-001
title: Throwie
type: reference
status: proposed
area: ui
source: https://throwie.app/
accessed: 2026-10-16
related:
  - "[[UI References]]"
created: 2026-10-16
updated: 2026-10-17
tags:
  - reference/ui
  - reference/typography
  - reference/needs-experimentation
---
# Throwie

## Identity
- **Source:** https://throwie.app/ (inspected 2026-10-16).
- **Purpose:** Shared reference for Roblox game graphics and text treatments across games; future tasks determine the application.
- **Evaluation: needs experimentation.** Captured reference, not a verified production tool or quality baseline. No assets have been made or tested in Roblox for this evaluation.
- **Source / licence:** External web application. Output usage rights and any input-font licences have not been verified.

## Observations (verified inspection)
The homepage describes an image-effects workflow: upload an image, use tools, export. Its interface lists metallic, halftone, grain, sketch, erosion, and many other effects. This inspection confirmed the available labels, not the quality or capabilities of each effect. No font-selection feature, export format, transparency support, or Roblox import workflow has been verified.

## Intent — interview with jg, 2026-10-16
- jg likes the overall range and wants experimentation to discover the specific qualities he likes.
- Distressed, eerie, hand-drawn treatments appeal to him. No styles are currently excluded; this is not a requirement to use those treatments in every game.
- Potential applications: game logos, menus, buttons, world signs, and thumbnails, when appropriate to the game.
- Study what the tool can actually do and use it when relevant.
- Keep the evaluation at **needs experimentation** until a few assets have been made and reviewed. Then update this note with findings and judge whether it is useful, including any limits.

## Interpretation and implementation recommendations
- **Inference:** Image effects could help develop distinctive text artwork from an input image containing text. This has not been tested.
- **Recommendation:** Compare a few treatments using the same original text artwork so the effect's contribution is clear. Preserve the input, effect names, settings, and outputs for reproducibility.
- **Recommendation:** Judge the result in its intended context, including readability at the actual display size. Small button labels may need a different treatment from a large logo.
- Use the game's art direction to choose effects; this reference does not approve a universal visual style or replace project requirements.

## Experiment and evidence to add
For each of a few assets, record: intended use, source artwork and font rights, effect and settings, output format and transparency, saved asset path, visual comparison, jg's judgment, and any Roblox import/readability test actually performed. Keep observations, inferences, and preferences separate.

## Open questions
- Which specific effects and combinations produce results jg likes?
- What export, resolution, transparency, and usage-rights limits apply?
- Which applications benefit enough to justify the workflow?

## Traceability
- No implementation tasks or production assets yet.
- Next stage: asset experiments, followed by an evidence-based usefulness assessment with jg.

## Review decision (2026-10-17)
- **Outcome:** propose a scoped experiment
- **Decided by:** jg
- **Summary:** First experiment run 2026-10-17: one generated neutral test image (white text on black, 1200x500), four tools at default settings (Erosion, Root Rot, Hyphae, Scribble), exported as PNG and compared at three display widths (90, 180, 340 px) on dark and light backgrounds. Exports are PNG with an alpha channel; Erosion, Hyphae and Scribble keep transparency, Root Rot exports an opaque white background. Tools differ in which luminance counts as ink: Erosion, Root Rot and Hyphae shape the white text, Scribble fills the dark areas, so on this input it covered the background and the text was unreadable. Black ink is invisible on a dark background without recoloring. Output size grows with bleed (Root Rot 1200x526, Scribble 1223x568). Hyphae took about 8 s to render. Root Rot and Erosion stayed readable at every size tested at defaults. The About page states 'Free for personal and commercial use'; credit optional. No uploaded image appeared in network requests (blob fetches, analytics beacons including an export_image event, Cloudflare RUM); POST bodies not inspected. Rights ledger class moves from unknown to permissive-claimed.
- **Evidence inspected:** Review packet; the live app (41 tools in 5 groups, About text, page code strings, network log); four PNG exports from throwie.app; two comparison matrices built with ffmpeg; alpha measured per export. Evidence archived under Media/REF-UI-001-Throwie/: Throwie-test-erosion-default.png, Throwie-test-rootrot-default.png, Throwie-test-hyphae-default.png, Throwie-test-scribble-default.png, Throwie-matrix-dark-90-180-340px.png, Throwie-matrix-light-90-180-340px.png (the input image was generated in the page and not saved)
- **Still unverified:** The other 37 tools; tuned settings (defaults only); the transparent-background parameter; the text config export; behaviour with real logo art and real fonts; Roblox import and in-game readability; licence beyond the one-line About statement; whether any image ever leaves the browser (POST bodies not read)
- **Next action:** Second round on one real logo or sign task: choose the input polarity per tool, try the recolor and transparent-background options, keep each tool's config export, and check the chosen output at real UI sizes in Studio (any upload needs jg's approval).
