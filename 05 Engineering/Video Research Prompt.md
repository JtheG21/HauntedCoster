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
---
# Video Research Prompt

Repeatable way to turn a video into one `RSH-` note. Draft process, not yet approved by jg.

## Rules
- One video, one note in `02 Research/`. No raw transcript in the vault.
- Use `/watch` for anything visual. NotebookLM is optional for long or multi-source material; paste its brief in with the URL.
- Claude drafts. jg reviews. Nothing becomes a lesson or a gate without evidence and approval.

## Prompt (paste into Claude Code)

```
/watch <VIDEO_URL>

Then write ONE research note for GAME-002 from this video.

Context for relevance: <one line: the feature or task this is for, e.g. "Journal UI redesign">

Do:
1. Check for an existing note first: grep -rl "<video id or title>" "02 Research" and update it instead of duplicating.
2. Check the matching folder in "10 References/" for related material and name the reference you compared against. Do not edit anything there.
3. Create "02 Research/RSH-<YYYYMMDD>-<Short-Topic>.md" from "99 Templates/T - Research.md". Use resolved values (real date, title). Keep every template heading. type: research, status: research, confidence: low unless frames AND audio/captions were both reviewed.
4. Sources table: video title, uploader, length, URL, access date. Add "Evidence limits": caption language/quality, whether frames were actually viewed.
5. "Observed mechanics (verified)": only what the video says or shows, each with a timestamp (m:ss). Mark speaker opinions as opinions. No measured claims without evidence.
6. Add "Visual check needed": timestamps where the transcript alone is insufficient. If frames were not viewed, say so.
7. "Hypotheses": each with confidence and how we would test it.
8. "Relevance to our game": link real notes with [[ID-Title]] (SYS-, ADR-, TASK-). Server authority, approved ADRs and AGENTS.md win over anything in the video.
9. "Original implementation ideas": our own. No copied assets, names, layouts or code.
10. "Recommendations" max 3. "Needs human review" lists every unverified conclusion. Put a "> Draft" line under the title.
11. Run python3 scripts/validate_vault.py and fix issues in this note only.

Don't: save the transcript, download media into the vault, create LES- or ADR- notes, or change existing approved notes.

End with: note path, what is unverified, and which timestamps I should view myself.
```

## Long videos: segmented Gemini (`scripts/watch_chunked.py`)
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
