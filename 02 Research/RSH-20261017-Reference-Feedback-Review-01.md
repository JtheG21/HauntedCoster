---
id: RSH-20261017-Reference-Feedback-Review-01
title: Reference Feedback Independent Review 01
type: research
status: research
sources:
  - "[[RSH-20261017-Reference-Feedback-Experiment]]"
confidence: high
created: 2026-10-17
updated: 2026-10-17
tags:
  - research/ui
related:
  - "[[RSH-20261017-Layered-UI-Production-Recipe]]"
---
# Reference Feedback Independent Review 01

## Question
Does the isolated experiment meet its scoped closeout requirements?

## Sources
Independent read-only agent review of the uncommitted branch against aca88e5, 2026-10-17. Local engine GuiObject documentation and source inspected. This research chore has no TASK entry; this is not a fabricated task audit gate.

## Findings
**Changes requested: one P2 blocker.** DecorationMotion.luau treePoint and thread positioning used an anchor pivot, while Roblox GuiObject Rotation is about the center regardless of AnchorPoint. The angled portrait thread could miss its intended endpoints by about 6 px. No other blockers reported. Physical hardware and published EditableImage/memory checks remain adoption limits.

## Recommendation
Rotate branch attachment points about the branch center; position each thread at the midpoint of its endpoints with a center anchor. Verify actual laid-out endpoints across both sway extrema, including portrait.

## Follow-up evidence
Corrected the center transform and midpoint positioning. Added verify-attachments.luau, comparing rendered line endpoints with actual branch bounds and spider heads over 100 samples. Desktop: max bark error 1.150 px, spider error 1.000 px. Narrow 420 px artwork: max bark error 1.201 px, spider error 1.064 px; both sampled branch rotation near -0.22 to +0.22 degrees. Errors remain under the 1.5 px layout-rounding threshold. Narrow test directly resized runtime artwork because the device simulator camera reported 1×1; this is geometry verification, not a new device screenshot or touch pass. Delta independent review pending.
