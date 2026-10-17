---
id: REF-UI-002
title: Resource Boy Exclusives
type: reference
status: proposed
area: ui
source: https://resourceboy.com/exclusives/
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[UI References]]"
  - "[[REF-UI-001-Throwie]]"
tags:
  - reference/ui
  - reference/vfx
  - reference/textures
  - reference/typography
  - reference/gradients
  - reference/needs-experimentation
---
# Resource Boy Exclusives

## Identity
- **Source:** https://resourceboy.com/exclusives/ (listing inspected 2026-10-16).
- **Purpose:** Shared resource discovery for making higher-quality Roblox games across projects. This entry lives with UI references but also covers potential VFX, texture and graphic-production uses.
- **Evaluation: needs experimentation.** No packs downloaded, assets created, or Roblox compatibility tests performed for this evaluation.
- **Source / licence:** Individual pack terms, formats, dependencies and permitted uses must be inspected before adopting assets; not verified by this listing inspection.

## Observations (verified listing only)
The exclusives page lists fonts, hand-drawn doodle and arrow elements, Photoshop brushes, gradients, textures, overlays, mockups, and text/logo effects. Examples include grunge and crayon textures, glitch overlays, lens flares, fog textures, and vintage letterpress effects. These are listing observations, not proof of the contents or quality of downloaded files. Photoshop-labelled resources may need an editing/export step; native Roblox compatibility has not been established.

## Intent — interview with jg, 2026-10-16
- The site's overall offering interests jg; keep discovery broad rather than restricting the reference to a single pack or current game.
- All three approaches are welcome: use suitable resources directly, modify/combine them into original assets, and study them for inspiration.
- Starting interests: VFX, textures, text effects and gradients. Explore other categories when relevant.
- Desired benefits: better visual quality, faster production and more distinctive results. Experimentation should reveal what delivers those benefits.
- Keep the site at **needs experimentation** and assess individual packs as they are tried. A single pack's result does not establish the usefulness of the entire site.

## Interpretation and implementation recommendations
- **Inference:** Suitable resources may contribute to Roblox interface art, logos, signs, thumbnails, surface graphics or VFX textures. Actual suitability depends on the pack and intended game.
- **Recommendation:** Inspect the selected pack's actual files and terms, adapt to the game's art direction, and test the finished output at its intended size and in context.
- **Recommendation:** For VFX candidates, verify the rendered texture and its behavior in the intended Roblox effect; a preview image alone is insufficient evidence.
- This reference authorizes consideration, not a universal style, a production-quality baseline, paid purchases or uploads.

## Experiment and evidence to add
Record findings per pack: exact source URL and access date, licence evidence, formats and editing dependencies, original preview/input, modifications and settings, saved output path, intended use, quality/readability or VFX test, effort required, and jg's judgment. Classify the result as useful for a stated context, not useful for a stated context, or unresolved. Link actual implementation tasks when they exist.

## Open questions
- Which packs produce useful results for the effort involved?
- Which formats and editing tools are required, and what rights apply?
- Which outputs retain quality and readability in Roblox?

## Traceability
- No implementation tasks or production assets yet.
- Related exploration: [[REF-UI-001-Throwie]]. The sources may complement one another; no combined workflow has been tested.

## Review decision (2026-10-17)
- **Outcome:** propose a scoped experiment
- **Decided by:** jg
- **Summary:** Licence page and two packs inspected 2026-10-17. The site lists 176 products (57 textures, 39 Photoshop brushes, 23 gradients, 21 patterns, 21 mockups, 9 graphics, 3 fonts, 3 text effects). For Exclusive-badge products designed by Resource Boy the licence allows unlimited personal and commercial use including client work, editing and combining, no attribution, and selling the final output; it forbids standalone redistribution, uploading to public or accessible private repositories (so pack files stay out of this repo), and making files available for download outside a final project, which leaves Roblox asset upload an open question. Third-party items in the list, such as Spicy Sauce Font (designed by Creatifitas Font), follow their own page licence. Brushes, gradients and the letterpress effect list Adobe Photoshop or Illustrator compatibility and need those tools. Direct zip links need no sign-in; the site loads many ad scripts. Packs examined: Lightning Bolt Textures (68 MB, 100 PNG, RGBA, about 950x3900, bolts on transparency) and Fog Textures (171 MB, 200 JPG, about 3840x2400-2800, grayscale fog on black, no alpha). A fog JPG converts to an RGBA PNG with luminance as alpha using ffmpeg. Both zips hold a short License.txt (identical in both, shorter than the web page) and a More Design Resources.txt. Rights ledger basis updated (class stays per-item). The packs are kept outside the repo at ~/Roblox-Work/resource-packs/resourceboy/ with a README.
- **Evidence inspected:** Review packet; the exclusives listing (7 pages, 176 product links); the License page; product pages for fog, lightning, spider web, smoke, grunge, doodle elements, fog brushes, purple gradients, vintage letterpress and Spicy Sauce Font; zip headers for six packs; two zips downloaded to scratch outside the repo (Lightning Bolt 71 MB, Fog 171 MB), listed, extracted, file formats and sizes measured, contact sheets viewed; one fog JPG converted to RGBA
- **Still unverified:** Any other pack; whether Roblox uploads of these textures (original or modified) are allowed; in-game appearance, memory cost and performance of 4K textures; how the textures look under Roblox lighting; whether the site's listing and licence stay stable; the in-zip licence versus the web page wording
- **Next action:** Run one pack through the Studio VFX and surface pads once they exist: Lightning Bolt Textures (PNG, RGBA) as bolt textures, and Fog Textures converted from JPG to RGBA (luminance to alpha) for a fog effect, judged at game camera distances by jg. Keep pack files outside the repo. Before any upload to Roblox, jg decides whether to ask Resource Boy (contact page) if uploaded game assets count as available for download outside a final project.
