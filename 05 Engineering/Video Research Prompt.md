---
id: ENG-Video-Research-Prompt
title: Video Research Prompt
type: index
status: proposed
created: 2026-10-14
updated: 2026-10-14
tags:
  - engineering/tooling
  - research
related:
  - "[[RSH-20261014-Good-UI-Principles-Video]]"
  - "[[RSH-20261014-Roblox-Game-95k-Monthly-Revenue-Video]]"
---
# Video Research Prompt

Repeatable way to turn a video into one `RSH-` note. Draft process, not yet approved by jg.

## Rules
- One video, one note in `02 Research/`. No raw transcript in the vault.
- Use `/watch` for anything visual. NotebookLM is optional for long or multi-source material; paste its brief in with the URL.
- Claude drafts. jg reviews. Nothing becomes a lesson or a gate without evidence and approval.
- **Batches:** jg may send several videos at once. Each gets its own note; one PR carries the batch. Check [[Video Research Index]] and `grep -rl "<video id>" "02 Research"` first, and add a row to the index in the same PR.
- **Concurrent sessions:** before any write, run `git worktree list` and confirm the branch; never reuse another session's worktree or branch, and check preflight's exit code explicitly (never pipe it).

## Prompt (paste into Claude Code)

Local engine only (decided by jg, 2026-10-14; `WATCH_ENGINE=local` in `~/.config/watch/.env`).

```
/watch:watch <VIDEO_URL>

Local engine only. Write ONE research note for GAME-002 from this video.
Context (required; ask me if blank): <the feature or decision this informs, e.g. "Journal UI redesign">
Not tied to the branch's current task unless stated here: <task id or "none">

Evidence recipe:
1. Transcript pass first; read the captions and pick cue timestamps.
2. Cue frames at --resolution 1024 for every "as you can see" moment, chart, dashboard or UI.
3. Sparse sweep (--fps 0.1, or keyframes) over any stretch with no scene changes; review as contact sheets.
   Skip steps 2-3 only if the transcript shows no on-screen visuals are referenced, and say so.
4. If the network drops, reuse the already-downloaded local media. If media fails, captions-only and confidence low.
5. Prefer on-screen text over auto-captions when they conflict, and note the conflict.

Do:
1. grep -rl "<video id>" "02 Research"; update an existing note instead of duplicating.
2. Check the matching folder in "10 References/"; name what you compared against, or say none found. List the related RSH- notes you link. Edit nothing there.
3. Create "02 Research/RSH-<YYYYMMDD>-<Short-Topic>.md" from "99 Templates/T - Research.md". Real values (date, title). Keep every template heading. type: research, status: research, project: GAME-002. Put a "> Draft" line under the title.
   Confidence: low = captions only; medium = captions AND frames reviewed across the whole video; never high from one creator's video.
4. Sources table: title, uploader, length, URL, access date. "Evidence limits": caption language/quality; frames viewed individually / via contact sheet / not viewed (give ranges).
5. "Observed mechanics (verified)": max ~10 bullets, each timestamped (m:ss) and tagged (speaker claim) / (shown on screen) / (opinion). No measured claims without evidence. Dashboard screenshots are still the creator's own unverified numbers.
6. "Visual check needed": timestamps still unresolved after the frame passes.
7. "Hypotheses": each with confidence and how we would test it.
8. "Relevance to our game": link real notes with [[ID-Title]] (SYS-, ADR-, TASK-). Add one "Transferability" line (genre, audience, platform mismatch with GAME-002). Server authority, approved ADRs and AGENTS.md win over anything in the video.
9. "Original implementation ideas": our own. No copied assets, names, layouts or code.
10. "Recommendations" max 3. "Needs human review" lists every unverified conclusion.
11. Run python3 scripts/validate_vault.py and fix issues in this note only.

Don't: save the transcript, put media in the vault, create LES- or ADR- notes, change approved notes, touch tasks/queue.json, or use Gemini. Delete only this run's disposable work dir.

End with: note path; what changed in confidence between passes; what is unverified; which timestamps I should view myself.
```

## Variants by video type
Use the prompt above and replace its two Context lines (and add the extra rules) for the video type. A variant changes the Context line, which reference folder to check, and a few extra requirements; it never relaxes the Don'ts or the evidence recipe. Drafts, not yet approved by jg; add new variants here as new video types come up.

### Variant: 3D models (modeling, topology, texturing/UVs, rigging)
Reference folder to check: `10 References/05 Misc/3D Model Quality Baseline.md` and the gallery. Never edit them from a video note.
```
Context (required): Build a shared vocabulary and checklist for what a professional, game-ready 3D model is, giving modeling, topology, texturing/UVs and rigging equal weight, so jg and Claude can judge model quality and write precise asset requests for GAME-002. Informs how we apply [[3D Model Quality Baseline]] and the finished-assets requirement in ADR-0011. Tag each point (general) or (Roblox-specific); add a Roblox-constraints line. Not tied to any task; do not change the baseline or gallery. One note per video, no synthesis note.
```
Extra rules: do not skip the frame passes (wireframes, UV layouts, texture maps and rig views are the evidence); add a Glossary group of defined terms with timestamps; add a "Roblox constraints" line (triangle budget, texture size, rig type, MeshPart import) and mark what the video does not cover as unverified.

### Variant: game systems / mechanics
Reference folder to check: `06 Code/Reference_Code/Reference_Code_Index.md`, and the matching `SYS-` notes.
```
Context (required): Understand how <system, e.g. an economy, capture loop, rotation or progression system> works in the video's game and which parts could inform <named GAME-002 system or SYS- note>. Separate what is shown from what is inferred. Server authority and approved ADRs win. Not tied to any task unless stated: <task id or none>.
```
Extra rules: write each mechanic as input, rule, output and where authority would sit (server or client); mark every number as a speaker claim unless a frame shows it; add a "Server-authority risk" line for anything that would need client trust.

### Variant: maps / environments
Reference folder to check: `10 References/02 Map/`.
```
Context (required): Learn layout, readability and pacing principles from the video's map or environment work that could inform GAME-002 <named area or habitat>, without copying its layout or assets. Not tied to any task unless stated: <task id or none>.
```
Extra rules: use cue frames for overhead views and landmarks; record scale and flow only if a frame shows them; add a "Playability" line (routes, sightlines, dead ends) that is marked unverified unless a frame shows it.

### Variant: UI
Reference folder to check: `10 References/01 UI/`.
```
Context (required): Extract UI principles from the video that could inform <named GAME-002 screen, e.g. HUD, Journal, Shop> without copying layouts or assets.
```
Extra rules: cue frames at 1024 px for every screen; list each principle with the on-screen example; add a "Readability on phone" line.

## Evidence recipe: commands
Set `S` to a scratchpad dir and `W` to the watch skill's `scripts/watch.py`.

```bash
# 1. captions + metadata, no frames
python3 $W "<URL>" --detail transcript --out-dir $S
# 2. cue frames (timestamps chosen from the transcript)
python3 $W "<URL>" --detail transcript --timestamps 0:21,1:03,4:29 --resolution 1024 --out-dir $S
# 3. sparse sweep over a range, reusing the local video.mp4 from step 2 if the network is flaky
python3 $W "<URL or local video.mp4>" --detail efficient --start 5:33 --end 16:38 --fps 0.1 --max-frames 70 --resolution 640 --no-dedup --no-whisper --out-dir $S
```

Why: the default scene-change sampler finds no frames in talking-head or slide-text stretches (2026-10-14: [[RSH-20261014-Roblox-Game-95k-Monthly-Revenue-Video]] had none past 5:33). Cue frames at 1024 px made dashboard and chart numbers legible that 512 px did not. Tile many sweep frames into a contact sheet with `ffmpeg ... -vf "scale=480:-2,tile=4x4"` to review them cheaply.

## Optional, not default: segmented Gemini (`scripts/watch_chunked.py`)
The default is now local only (see above). Kept for reference; use it only if jg asks for the Gemini engine.

Whole-video Gemini requests for long videos often fail with HTTP 503 (2026-10-14: a 27-minute video failed on every attempt while short clips succeeded). The wrapper runs the `/watch` Gemini engine in 2-5 minute segments with retries and writes one combined report outside the vault.

```bash
python3 scripts/watch_chunked.py "<VIDEO_URL>" --dry-run        # show the segment plan, no requests
python3 scripts/watch_chunked.py "<VIDEO_URL>" --question "<what you need>" --segment 300 --retries 3
```

- It prints the path of `report.md` (a temp dir by default). Use it as evidence for the `RSH-` note; never copy it into the vault whole.
- **Free-tier limit:** `gemini-3.7-flash` allowed 20 requests per day on the free tier (2026-10-14), and retries count. A daily-quota 429 stops the run. Plan roughly one request per 5 minutes of video plus retries.
- **No silent fallback.** Failed segments are listed in the report. Decide yourself whether to rerun later or use `watch.py --engine local`.
- **Provenance.** Gemini's answer is secondary evidence. Segments can contradict each other (it did once on 2026-10-14). Say so in "Evidence limits" and keep `confidence` at `medium` or lower until frames are viewed.
- Tests: `python3 -m unittest tests.test_watch_chunked`.

## Optional NotebookLM pre-pass

```
Produce a structured brief of this video for another AI to act on:
1. One-paragraph summary
2. Every distinct principle/claim, with the exact timestamp
3. Concrete examples shown or described (what was on screen, numbers, names)
4. Actionable rules or checklists, in the speaker's wording where possible
5. Anything uncertain, opinion, or contradicted elsewhere
6. Timestamps where visuals matter and the transcript alone is insufficient
```
