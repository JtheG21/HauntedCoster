---
id: EXP-0001
title: M2 Validation Experiments
type: experiment
project: GAME-001
status: proposed
start:
end:
metric: see table
created: 2026-10-10
updated: 2026-10-10
tags:
  - metrics/validation
related:
  - "[[01 Game Design]]"
---
# EXP-0001: M2 validation experiments (proposed)

These are designed to **disprove** the riskiest assumptions in [[01 Game Design]] cheaply, using the M2 prototype in **local Studio tests and private sessions only**. No ads, purchases or publishing.

## Sample-size honesty
Early tests involve **5–10 people** (friends, family, a small Discord). That's enough to spot clear failures (confusion, frustration, bugs), **not** enough to estimate retention or conversion. There are no universal benchmark targets. Thresholds below are *decision triggers* for small samples, not success claims. Stronger evidence later comes from a **soft-launched private or unlisted test** (with your approval) using Roblox Creator Analytics: <60 s bounce, D1/D7, session length.

| # | Question | Procedure | Measurable observations | Minimum evidence | Decision it informs |
|---|---|---|---|---|---|
| **A. Core fun** | Do new players enjoy the loop within minutes? | 2–4 players play 3 matches without coaching. Observe, then a 3-question survey (1–5: fun, want-another, understood) | Unprompted laughter or engagement moments; "want another match" rating; quits before match 3 | ≥6 testers. If **≥ half** rate "want another" at 4–5 and no one quits early → continue. If most are ≤2 → rework the gate/finale design before M3 | Go / rework / pivot (fallback to candidate B) |
| **B. Usability** | Are the objective, controls, powers and gates clear without explanation? | Same sessions. Time to first power use; count "what do I do?" questions; can players say what a gate needs? | Seconds to first power use (logged on the server); confusion count per match | Median first power use **<60 s**; ≤1 confusion question per player per match | Onboarding changes |
| **C. Replayability** | Do players want another round voluntarily? | After the required 3 matches, say "you can stop". Record who keeps playing | Voluntary extra matches; which section or gate is mentioned as the favourite or worst | ≥ a third play a 4th match voluntarily | Module variety and gate design priorities |
| **D. Technical** | Does it work reliably with several players? | Studio "Server and Clients" with 2 and 4 clients (once automation is unblocked, or manually), plus 1 real 2-device session including **mobile** | Server errors in Output; ability desync reports; exploit probes (client fires abilities faster or out of range → rejected); server frame time | 0 unhandled errors in 10 matches; 100% of exploit probes rejected; no reported ability "felt wrong" desync in 2-device play | Network ownership approach (spike result) |
| **E. Monetization** | Is there a genuine cosmetic benefit players would want, without unfair advantage? | Show 3 cosmetic mockups (power VFX colour, trail, finale emote) after testing; ask which they'd want and why. **No real purchase** | Ranking of cosmetics; do any testers *expect* paid power (a red flag to avoid)? | Qualitative only. ≥ half pick at least one cosmetic they'd "want" | Which cosmetic lines to build in M6 |

## Data collection
- Server-side logging in the prototype: time to first power use, gate wait times, Echo usage, match length, finale winners. The game stores the logs; there's no personal data.
- Results go into `TEST-` notes (one per session) and are summarised here under **Result**.

## Ethics
Testers or their parents agree. Minors only with parental awareness. No recordings without consent. No real-money purchases.

## Result
*(after M2 sessions)*

## Decision
*(go / rework / pivot, which needs human approval)*
