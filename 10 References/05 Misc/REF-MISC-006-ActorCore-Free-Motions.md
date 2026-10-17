---
id: REF-MISC-006
title: ActorCore — Free Motion Exploration
type: reference
status: proposed
area: misc
source: https://actorcore.reallusion.com/3d-motion/free?searchType=1
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[Misc References]]"
  - "[[Resource Catalog]]"
tags:
  - reference/misc
  - reference/animation
  - reference/needs-experimentation
---
# ActorCore — Free Motion Exploration

## Identity
- **Supplied source:** https://actorcore.reallusion.com/3d-motion/free?searchType=1
- **Accessible catalog evidence:** https://actorcore.reallusion.com/3d-motion/free?motionTech=Mocap&saleType=Items
- **Purpose:** Explore an additional source of motion for Roblox game production across projects.
- **Evaluation: needs experimentation.** No account connection, motion download, playback inspection, retargeting or Roblox test performed. Experiments deferred to the later note-by-note review.

## Observations and evidence limits
The exact supplied URL could not be opened by the web reader. Official-domain search results for the alternate free catalog were inspected on 2026-10-16 and listed movement, dance, spell-casting and combat-related clips marked free. This confirms listing descriptions, not actual motion quality, continuing availability or entitlement for every item.

Official Reallusion documentation/search material describes motion export workflows and FBX/BVH support. Per-item formats, required software, account steps, usage terms and suitability for Roblox publishing have not been verified. Export support does not establish R6/R15 or custom-rig compatibility. No claim of direct Roblox integration is made.

## Intent — interview with jg, 2026-10-16
- Interests include library variety, motion quality, saving production time and discovering actions.
- All three uses are welcome: suitable ready-made motion, editing/combining clips and studying movement for original animation.
- Explore anything relevant, including player/NPC movement, combat, emotes and cutscenes when needed.
- **Free only.** Do not shortlist paid motions or propose a paid subscription as the default. Confirm an individual selection is actually free at the time of use.
- Mark needs experimentation. Compare quality, retargeting effort and usefulness with the existing animation pipeline before adopting another workflow.

## Interpretation and possible application
- **Hypothesis:** Free clips may fill gaps in the existing library or provide useful motion references.
- **Recommendation for later review:** Search the existing Mixamo/Roblox animation catalog first, as linked in [[Resource Catalog]]. Choose a relevant free ActorCore clip only when a real task reveals a gap or useful comparison.
- Inspect actual motion, source rig, timing and export options. Test retargeting on the intended Roblox rig, including contacts, foot sliding, joint limits, root motion, scale, looping and transitions as applicable.
- Verify the specific item's terms and export/publishing permissions before using it. Free price does not establish unrestricted redistribution or permission to store source files in this repository.
- Do not assume the existing Mixamo tooling supports ActorCore files unchanged; assess the input skeleton and conversion requirements first.

## Experiment and evidence to add
Record exact free clip URL and access date, entitlement/terms evidence, source/export format and rig, dependencies, intended use, existing-library baseline, adapted output, motion comparison, actual Roblox playback checks, effort and jg's judgment. Record failures and limits. No paid calls, purchases or uploads are authorized by capture.

## Open questions
- Which free motions fill a useful gap?
- What retargeting changes are needed for R6, R15 or a particular custom rig?
- Does the result justify extra setup versus existing resources?

## Traceability
- Capture only: no motion acquired or pipeline changed.
- Next action: review later with jg and select a scoped free-motion experiment if worthwhile.

## Review decision (2026-10-17)
- **Outcome:** investigate a specific gap
- **Decided by:** jg
- **Summary:** Review 2026-10-17 of a free-motion resource. Sources opened: the ActorCore free listing and the Magic Spell Cast 05 item and info tabs, the ActorCore licence page and the Content EULA (updated 2025-08-01) in full; nothing was signed up for, added to a cart or downloaded. The free listing shows items marked FREE at 0 USD, with a banner offering up to 10 free daily downloads after sign-up, so downloading needs a Reallusion member account, which only jg can create, and creating an account counts as accepting the EULA. The Magic Spell Cast 05 item (vendor Studio Black; tags sorceress, shout, magical power, realistic, fantasy) shows a Standard License at 0 USD and points to the paid Magical Moves pack, so it is a sample; the page shows no frame count, rate or format, and secondhand forum reports that downloads are FBX only are unverified. EULA findings: the Standard License allows incorporating Content into one's own creations for commercial games, AR/VR projects and interactive services; it forbids importing, uploading, reproducing, making available, publishing, transmitting, distributing or sublicensing the Content to any third party, and forbids use as embedded content within applications or online services, in paid in-software content, and for machine learning or AI training; the licence page's rights table lists games and interactive applications as allowed under Standard and embedding in any application or service as Enterprise only. Publishing a retargeted motion as a Roblox animation asset uploads it to a third-party service where it is embedded in an online application, which arguably runs into those restrictions; the text does not settle it, so it needs Reallusion's written answer. Our existing Mixamo-to-Roblox catalog has 15 distinct animations (25 published counting R15 and R6): breathing idle, combat idle, crouch walk, fall, happy idle, hip hop dance, jump, jumping jacks, punch, run, salute, sword slash, victory pose, walk and wave; lookups for spell, cast and magic return no match, so spell casting is a real gap. Rights ledger basis updated; class stays per-item. The retargeting questions in the note (foot sliding, joint limits, root motion, scale) stay untested.
- **Evidence inspected:** Review packet; the ActorCore free listing and one item page with its info tab in the built-in browser; the ActorCore licence page and the Content EULA read in full; a web search whose results were secondhand and conflicting on game use (not relied on); read-only lookups in our Mixamo pipeline catalog; no sign-in, cart, download or contact
- **Still unverified:** Whether a Roblox animation upload is permitted under the Standard License (needs Reallusion's written answer); the format, frame rate and skeleton of any free motion; retargeting quality on R15, R6 or a custom rig; whether the free sample items stay free; daily-download mechanics after sign-up
- **Next action:** Resolve the licence question first: whether publishing a retargeted ActorCore motion as a Roblox animation asset, used only inside jg's own Roblox games, fits the Standard License given the EULA restrictions on uploading or making Content available to third parties and on embedded content in online services. Until Reallusion answers in writing, no download, retarget or upload of any ActorCore motion, and no account creation by Claude. Draft inquiry for jg to review and send (not sent by Claude): 'Subject: Licensing question: ActorCore Standard License and Roblox animation assets. Hello, I develop games on Roblox and am considering ActorCore motions, including free items such as Magic Spell Cast 05. I would retarget a motion to the Roblox rig and publish it as an animation asset on Roblox, used only inside my own games. The Content EULA (updated 2025-08-01) allows games and interactive services under the Standard License, but also says Content may not be uploaded or made available to third parties and may not be used as embedded content within applications or online services. Does publishing a retargeted motion as a Roblox animation asset, for use only in my own Roblox games, fall within the Standard License, or does it need an Enterprise license? Thank you.' Spell casting is a real gap in our catalog (lookups for spell, cast and magic return no match), so if the answer is no, consider Mixamo or original animation instead.
