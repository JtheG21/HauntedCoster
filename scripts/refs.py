#!/usr/bin/env python3
"""Reference library tooling for `10 References/` (standard library only).

Reads the REF-* notes on demand; there is no stored registry, so nothing can drift (REF-MISC-002).

  refs.py list                          every REF note: status, review checkbox, citing tasks
  refs.py brief --category vfx[,ui]     short brief of the matching notes (Intent, open questions, media)
  refs.py brief --task TASK-0001        same, from the task note's Category and References lines
  refs.py brief --ids REF-VFX-001       explicit notes
  refs.py trace                         which tasks cite which REF, and REF notes nothing cites
  refs.py lint [--file PATH]            frontmatter, ids, embeds, Index and Catalog rows
  refs.py guard [--staged | --base REF] flag edits to jg's Intent sections and moves to `approved`, and refuse staged
                                        files that are byte-identical to files in ~/Roblox-Work/resource-packs (licences forbid repo storage)
  refs.py actions [--by-blocker|--id ID] every reviewed note's outcome, next action and what it waits on
  refs.py new --area map --title "X"    scaffold the next REF-<AREA>-NNN from T - Reference
  refs.py review-next [--id REF-ID]     review packet for the next unchecked item (or a named one)
  refs.py decide REF-ID --outcome ...   record jg's decision: append a dated section, tick the Index, note the Catalog (dry run unless --apply)
  refs.py pin [--ids A,B]               record source commit + licence of GitHub-sourced notes (read-only gh api)
  refs.py drift [--links]               compare the latest pins with upstream HEAD; optionally HEAD-check source URLs
  refs.py rights [--check ID --use code|asset|method]   licence class per note and the adaptation gate
  refs.py ledger [--refs A,B]           what tasks citing a REF cost: revisions, elapsed, tokens, jg's floor verdict

Spec: 02 Research/RSH-20261017-Reference-Automation-Spec.md. It never writes inside an existing
note or touches Intent sections; `new` only creates a file, `pin` only appends to tasks/reference-pins.jsonl.
Exit codes: 0 ok, 1 problems found, 2 usage error.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
import re
import statistics
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import task_store  # noqa: E402
from validate_vault import STATUSES, parse_frontmatter  # noqa: E402

REF_DIR = "10 References"
INDEX = "00 Studio/Reference Review Index.md"
CATALOG = "00 Studio/Resource Catalog.md"
TEMPLATE = "99 Templates/T - Reference.md"
PINS = "tasks/reference-pins.jsonl"
RIGHTS = "00 Studio/reference-rights.json"
USAGE = "tasks/usage-ledger.jsonl"
RIGHTS_CLASSES = ("permissive-verified", "permissive-claimed", "copyleft", "platform-terms", "per-item",
                  "unknown", "reference-only")
ID_RE = re.compile(r"^REF-([A-Z]+)-(\d{3})$")
REF_IN_TEXT = re.compile(r"REF-[A-Z]+-\d{3}")
FOLDER_AREA = {"01 UI": "ui", "02 Map": "map", "03 Sounds": "sfx", "04 Vfx": "vfx", "05 Misc": "misc", "06 Code": "code"}
AREA_FOLDER = {v: k for k, v in FOLDER_AREA.items()}

# Task Intake classification -> the `reference/<tag>` tags a note carries (frontmatter tags).
CATEGORY_TAGS = {
    "reference": ["reference/ui", "reference/map", "reference/vfx"],
    "map": ["reference/map", "reference/atmosphere"],
    "asset": ["reference/modeling"],
    "vfx": ["reference/vfx", "reference/animation", "reference/cutscene"],
    "ui": ["reference/ui", "reference/typography", "reference/gradients"],
    "audio": ["reference/audio", "reference/sfx"],
    "systems": ["reference/automation", "reference/workflow", "reference/research", "reference/code"],
    "game": ["reference/art-direction", "reference/map"],
}
# Task Intake lines name workflows, e.g. "Audio -> [[Audio Workflow]]".
WORKFLOW_CATEGORY = {"reference analysis": "reference", "map workflow": "map", "asset workflow": "asset",
                     "vfx workflow": "vfx", "ui workflow": "ui", "audio workflow": "audio",
                     "systems workflow": "systems", "game production workflow": "game"}
ALWAYS = ("REF-CODE-007", "REF-MISC-002")  # govern how any Standard/Deep brief is written


def ref_notes(root: Path) -> list[Path]:
    return sorted((root / REF_DIR).rglob("REF-*.md")) if (root / REF_DIR).is_dir() else []


def ref_id(path: Path) -> str:
    m = re.match(r"^(REF-[A-Z]+-\d{3})", path.name)
    return m.group(1) if m else path.stem


def sections(text: str) -> dict[str, str]:
    """Map each `## Heading` to its body (everything up to the next `## `)."""
    out: dict[str, str] = {}
    parts = re.split(r"(?m)^## (.+)$", text)
    for i in range(1, len(parts), 2):
        out[parts[i].strip()] = parts[i + 1]
    return out


def section(text: str, prefix: str) -> str | None:
    for name, body in sections(text).items():
        if name.startswith(prefix):
            return body.strip()
    return None


def load(path: Path) -> tuple[dict, str]:
    text = path.read_text(encoding="utf-8")
    return parse_frontmatter(text) or {}, text


def tags_of(fm: dict) -> list[str]:
    t = fm.get("tags", [])
    return t if isinstance(t, list) else [t]


def task_notes(root: Path) -> dict[str, Path]:
    out = {}
    for p in (root / "03 Games").rglob("TASK-*.md") if (root / "03 Games").is_dir() else []:
        m = re.match(r"^(TASK-\d{4})", p.name)
        if m:
            out[m.group(1)] = p
    return out


def cited_by(root: Path) -> dict[str, set[str]]:
    """REF id -> task ids, from each task note's `**References:**` line."""
    cites: dict[str, set[str]] = {}
    for tid, p in task_notes(root).items():
        for line in p.read_text(encoding="utf-8").splitlines():
            if "**References:**" in line:
                for r in REF_IN_TEXT.findall(line):
                    cites.setdefault(r, set()).add(tid)
    return cites


def review_checks(root: Path) -> dict[str, bool]:
    idx = root / INDEX
    out: dict[str, bool] = {}
    if idx.exists():
        for line in idx.read_text(encoding="utf-8").splitlines():
            m = re.match(r"^\|\s*\[( |x|X)\]\s*\|\s*\[\[(REF-[A-Z]+-\d{3})", line)
            if m:
                out[m.group(2)] = m.group(1).lower() == "x"
    return out


# --------------------------------------------------------------------------- list / trace

def cmd_list(root: Path) -> int:
    cites, checks = cited_by(root), review_checks(root)
    print(f"{'ID':14} {'status':9} {'reviewed':8} {'tasks':5}  title")
    for p in ref_notes(root):
        fm, _ = load(p)
        rid = ref_id(p)
        rev = {True: "yes", False: "no"}.get(checks.get(rid), "-")
        print(f"{rid:14} {str(fm.get('status', '?')):9} {rev:8} {len(cites.get(rid, ())):5}  {fm.get('title', '')}")
    return 0


def cmd_trace(root: Path) -> int:
    cites = cited_by(root)
    ids = [ref_id(p) for p in ref_notes(root)]
    for rid in ids:
        if rid in cites:
            print(f"{rid}: {', '.join(sorted(cites[rid]))}")
    unused = [r for r in ids if r not in cites]
    print(f"not cited by any task ({len(unused)}): {', '.join(unused) if unused else '-'}")
    return 0


# --------------------------------------------------------------------------- brief

def clip(body: str, limit: int) -> str:
    lines = [ln for ln in body.splitlines() if ln.strip()]
    more = len(lines) - limit
    return "\n".join(lines[:limit]) + (f"\n  ... (+{more} more lines in the note)" if more > 0 else "")


def brief_one(root: Path, p: Path, max_lines: int) -> str:
    fm, text = load(p)
    rid = ref_id(p)
    out = [f"### {rid} {fm.get('title', '')}  [{fm.get('status', '?')}]  {p.relative_to(root)}"]
    purpose = re.search(r"(?m)^- \*\*Purpose:\*\*\s*(.+)$", text)
    if purpose:
        out.append(f"Purpose: {purpose.group(1).strip()}")
    for label, prefix in (("Intent", "Intent"), ("Open questions", "Open questions")):
        body = section(text, prefix)
        if body:
            out.append(f"{label}:\n{clip(body, max_lines)}")
    media = sorted(set(re.findall(r"!\[\[([^\]]+\.(?:mp4|jpg|jpeg|png))\]\]", text)))
    if media:
        out.append("Media: " + ", ".join(media[:8]) + (f" (+{len(media) - 8})" if len(media) > 8 else ""))
    related = sorted({r for r in REF_IN_TEXT.findall(" ".join(fm.get("related", []) or [])) if r != rid})
    if related:
        out.append("Also see: " + ", ".join(related))
    return "\n".join(out)


def categories_from_task(root: Path, tid: str) -> tuple[set[str], list[str], Path]:
    notes = task_notes(root)
    if tid not in notes:
        raise SystemExit(f"refs: no task note found for {tid}")
    text = notes[tid].read_text(encoding="utf-8")
    cats: set[str] = set()
    explicit: list[str] = []
    for line in text.splitlines():
        low = line.lower()
        if "**category" in low:
            cats |= {c for k, c in WORKFLOW_CATEGORY.items() if k in low}
            for word in CATEGORY_TAGS:
                if re.search(rf"\b{word}\b", low):
                    cats.add(word)
        if "**references:**" in low:
            explicit += REF_IN_TEXT.findall(line)
    return cats, explicit, notes[tid]


def cmd_brief(root: Path, category: str | None, task: str | None, ids: str | None, tier: str, max_lines: int) -> int:
    cats: set[str] = set(filter(None, (category or "").lower().split(",")))
    wanted: list[str] = [i.strip() for i in (ids or "").split(",") if i.strip()]
    where = []
    if task:
        tcats, explicit, note = categories_from_task(root, task)
        cats |= tcats
        wanted += explicit
        where.append(f"{task} ({note.name})")
    unknown = cats - set(CATEGORY_TAGS)
    if unknown:
        print(f"refs: unknown category {sorted(unknown)}; use {sorted(CATEGORY_TAGS)}", file=sys.stderr)
        return 2
    if not cats and not wanted:
        print("refs: give --category, --task or --ids", file=sys.stderr)
        return 2
    tagset = {t for c in cats for t in CATEGORY_TAGS[c]}
    notes = {ref_id(p): p for p in ref_notes(root)}
    picked: list[str] = []
    for rid, p in notes.items():
        fm, _ = load(p)
        if rid in wanted or tagset & set(tags_of(fm)):
            picked.append(rid)
    for rid in wanted:
        if rid not in notes:
            print(f"refs: {rid} is not a REF note in this checkout", file=sys.stderr)
    print(f"# Reference brief {'for ' + ', '.join(where) if where else ''}".rstrip())
    print(f"Categories: {', '.join(sorted(cats)) or '-'}. Treat `approved` as jg's preference, not proof; "
          "open media only for the beat you need. Rights are unverified unless a note says otherwise.\n")
    if not picked:
        print("No matching reference notes. Follow the project's conventions (Task Intake step 5).")
    for rid in picked:
        print(brief_one(root, notes[rid], max_lines) + "\n")
    if tier in ("standard", "deep"):
        rest = [r for r in ALWAYS if r in notes and r not in picked]
        if rest:
            print("Method notes for Standard/Deep briefs: " + ", ".join(rest))
    return 0


# --------------------------------------------------------------------------- lint

def name_index(root: Path) -> set[str]:
    names: set[str] = set()
    for p in root.rglob("*"):
        rel = p.relative_to(root)
        if any(part.startswith(".") for part in rel.parts) or rel.parts[0] in ("node_modules",):
            continue
        if p.is_file():
            names.add(p.name.lower())
            names.add(p.stem.lower())
    return names


def catalog_states(root: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    cat = root / CATALOG
    if cat.exists():
        for line in cat.read_text(encoding="utf-8").splitlines():
            m = re.search(r"\[\[(REF-[A-Z]+-\d{3})[^\]]*\]\]", line)
            if m and line.startswith("|"):
                cells = [c.strip() for c in line.strip().strip("|").split("|")]
                out[m.group(1)] = cells[2].lower() if len(cells) > 3 else ""
    return out


STATE_OK = {"proposed": {"captured", "proposed"}, "approved": {"approved"}}


def lint_note(root: Path, p: Path, names: set[str], states: dict[str, str], index_text: str) -> list[str]:
    rel = str(p.relative_to(root))
    errs: list[str] = []
    fm, text = load(p)
    if not fm:
        return [f"{rel}: missing YAML frontmatter"]
    for k in ("id", "title", "type", "status", "area", "source", "created", "updated"):
        if k not in fm:
            errs.append(f"{rel}: missing '{k}'")
    rid = ref_id(p)
    m = ID_RE.match(str(fm.get("id", "")))
    if not m:
        errs.append(f"{rel}: id '{fm.get('id')}' is not REF-<AREA>-NNN")
    elif fm.get("id") != rid:
        errs.append(f"{rel}: id '{fm.get('id')}' does not match filename prefix '{rid}'")
    if fm.get("type") != "reference":
        errs.append(f"{rel}: type must be 'reference'")
    if fm.get("status") not in STATUSES:
        errs.append(f"{rel}: status '{fm.get('status')}' not in the controlled vocabulary")
    area = str(fm.get("area", ""))
    folder_area = next((a for f, a in FOLDER_AREA.items() if f"/{f}/" in f"/{p.relative_to(root).as_posix()}"), None)
    if folder_area and area and area != folder_area:
        errs.append(f"{rel}: area '{area}' but the note lives under the {folder_area} folder")
    if m and area and m.group(1).lower() != area:
        errs.append(f"{rel}: id area {m.group(1)} does not match area '{area}'")
    for key in ("created", "updated"):
        if key in fm and not re.match(r"^\d{4}-\d{2}-\d{2}$", str(fm[key])):
            errs.append(f"{rel}: {key} is not an ISO date")
    body = re.sub(r"```.*?```", "", text, flags=re.S)
    for target in re.findall(r"!\[\[([^\]|#]+)", body):
        if target.strip().lower() not in names:
            errs.append(f"{rel}: embed ![[{target}]] resolves to no file")
    for lp in re.findall(r"(?m)^- \*\*Local (?:source|video):\*\*\s*`([^`]+)`", text):
        if not (root / lp).exists():
            errs.append(f"{rel}: local path `{lp}` does not exist")
    if f"[[{p.stem}" not in index_text and index_text:
        errs.append(f"{rel}: no row in the Reference Review Index")
    if rid not in states:
        errs.append(f"{rel}: no row in the Resource Catalog")
    elif fm.get("status") in STATE_OK and states[rid] not in STATE_OK[fm["status"]]:
        errs.append(f"{rel}: status '{fm['status']}' but Catalog state '{states[rid]}'")
    return errs


def cmd_lint(root: Path, file: str | None) -> int:
    paths = ref_notes(root)
    if file:
        target = Path(file).resolve()
        paths = [p for p in paths if p.resolve() == target]
        if not paths:
            return 0  # not a REF note
    index = root / INDEX
    index_text = index.read_text(encoding="utf-8") if index.exists() else ""
    names, states = name_index(root), catalog_states(root)
    errs: list[str] = []
    for p in paths:
        errs += lint_note(root, p, names, states, index_text)
    ids = [ref_id(p) for p in ref_notes(root)]
    if (root / RIGHTS).exists():
        rights = read_rights(root)
        for rid in ids:
            if rid not in rights:
                errs.append(f"{RIGHTS}: no entry for {rid}")
            elif rights[rid].get("class") not in RIGHTS_CLASSES or not rights[rid].get("basis"):
                errs.append(f"{RIGHTS}: {rid} needs a class from {RIGHTS_CLASSES} and a basis")
        for rid in set(rights) - set(ids):
            errs.append(f"{RIGHTS}: entry for unknown note {rid}")
    for dup in {i for i in ids if ids.count(i) > 1}:
        errs.append(f"duplicate reference id {dup}")
    for e in errs:
        print("ERROR", e)
    print(f"refs lint: {len(paths)} notes, {len(errs)} errors")
    return 1 if errs else 0


# --------------------------------------------------------------------------- guard

def guard_issues(rel: str, old: str | None, new: str) -> list[str]:
    """Edits that need jg: a changed Intent section, or `status` moving to approved."""
    if old is None:
        return []  # a new capture note starts with its own interview
    issues = []
    if section(old, "Intent") != section(new, "Intent"):
        issues.append(f"{rel}: the '## Intent' section (jg's interview) changed")
    ofm, nfm = parse_frontmatter(old) or {}, parse_frontmatter(new) or {}
    if ofm.get("status") != "approved" and nfm.get("status") == "approved":
        issues.append(f"{rel}: status moved to 'approved' (only jg approves)")
    return issues


def git(root: Path, *args: str) -> str | None:
    r = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None


PACKS_DIR_DEFAULT = Path.home() / "Roblox-Work" / "resource-packs"
MIN_PACK_FILE = 4096  # smaller files (README, licence text) are never flagged


def packs_dir() -> Path:
    return Path(os.environ.get("REFS_PACKS_DIR", str(PACKS_DIR_DEFAULT)))


def pack_index(d: Path) -> dict[int, list[Path]]:
    """Size -> pack files of that size (stat only, so the common case costs no hashing)."""
    idx: dict[int, list[Path]] = {}
    for p in d.rglob("*"):
        try:
            if p.is_file() and not p.name.startswith("."):
                size = p.stat().st_size
                if size >= MIN_PACK_FILE:
                    idx.setdefault(size, []).append(p)
        except OSError:
            continue
    return idx


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def blob_bytes(root: Path, spec: str) -> bytes | None:
    r = subprocess.run(["git", "-C", str(root), "show", spec], capture_output=True)
    return r.stdout if r.returncode == 0 else None


def pack_leaks(root: Path, changed: list[str], spec_of) -> list[str]:
    """Changed files byte-identical to a file in the resource-packs folder. Not overridable."""
    d = packs_dir()
    if not d.is_dir():
        return []
    idx = pack_index(d)
    if not idx:
        return []
    cache: dict[Path, str] = {}
    issues = []
    for f in changed:
        data = blob_bytes(root, spec_of(f))
        if data is None or len(data) < MIN_PACK_FILE or len(data) not in idx:
            continue
        digest = hashlib.sha256(data).hexdigest()
        for cand in idx[len(data)]:
            if cache.setdefault(cand, sha256_of(cand)) == digest:
                issues.append(f"{f} is byte-identical to {cand}; the Resource Boy and ActorCore licences forbid "
                              "storing pack files in a repository (REF-UI-002, REF-MISC-006). Remove it from the commit.")
                break
    return issues


def cmd_guard(root: Path, staged: bool, base: str | None) -> int:
    if staged:
        changed = (git(root, "diff", "--cached", "--name-only", "--diff-filter=AM") or "").splitlines()
        old_of = lambda f: git(root, "show", f"HEAD:{f}")  # noqa: E731
        new_of = lambda f: git(root, "show", f":{f}")  # noqa: E731
    else:
        base = base or "main"
        changed = (git(root, "diff", "--name-only", "--diff-filter=AM", f"{base}...HEAD") or "").splitlines()
        old_of = lambda f: git(root, "show", f"{base}:{f}")  # noqa: E731
        new_of = lambda f: git(root, "show", f"HEAD:{f}")  # noqa: E731
    issues: list[str] = []
    for f in changed:
        if f.startswith(REF_DIR + "/") and Path(f).name.startswith("REF-") and f.endswith(".md"):
            new = new_of(f)
            if new is not None:
                issues += guard_issues(f, old_of(f), new)
    leaks = pack_leaks(root, changed, (lambda f: f":{f}") if staged else (lambda f: f"HEAD:{f}"))
    for lk in leaks:
        print("GUARD pack-leak", lk)  # no override: this is a licence rule, not jg's preference
    if issues and os.environ.get("REFS_JG_APPROVED") == "1":
        print("refs guard: jg-approved override set; allowing:\n  " + "\n  ".join(issues))
        return 1 if leaks else 0
    for i in issues:
        print("GUARD", i)
    if issues:
        print("These are jg's preferences/approvals. If jg asked for exactly this edit, rerun the commit with "
              "REFS_JG_APPROVED=1 and say so in the commit message.")
    return 1 if (issues or leaks) else 0


# --------------------------------------------------------------------------- new

def cmd_new(root: Path, area: str, title: str, dry: bool) -> int:
    area = area.lower()
    if area not in AREA_FOLDER:
        print(f"refs: area must be one of {sorted(AREA_FOLDER)}", file=sys.stderr)
        return 2
    nums = [int(m.group(2)) for p in ref_notes(root) if (m := ID_RE.match(ref_id(p))) and m.group(1) == area.upper()]
    rid = f"REF-{area.upper()}-{max(nums, default=0) + 1:03d}"
    slug = re.sub(r"[^A-Za-z0-9]+", "-", title).strip("-")
    folder = root / REF_DIR / AREA_FOLDER[area]
    if area == "code":
        folder = folder / "Reference_Code"
    dest = folder / f"{rid}-{slug}.md"
    tpl = root / TEMPLATE
    if not tpl.exists():
        print(f"refs: template missing: {TEMPLATE}", file=sys.stderr)
        return 2
    today = datetime.date.today().isoformat()
    text = tpl.read_text(encoding="utf-8")
    text = text.replace("REF-AREA-000", rid).replace("{{title}}", title).replace("area: map", f"area: {area}")
    text = text.replace("{{date:YYYY-MM-DD}}", today)
    print(f"{'would create' if dry else 'created'} {dest.relative_to(root)}")
    if not dry:
        folder.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            print("refs: file exists", file=sys.stderr)
            return 2
        dest.write_text(text, encoding="utf-8")
    print(f"Next: add a row to the area index, a Review Index row (| [ ] | [[{dest.stem}]] — {title} | … |) "
          f"and a Resource Catalog row, then run `scripts/refs.py lint`.")
    return 0


# --------------------------------------------------------------------------- pin / drift

def gh(*args: str) -> str | None:
    """Read-only GitHub API call through `gh`; None on any failure. Tests replace this."""
    try:
        r = subprocess.run(["gh", "api", *args], capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


def github_repo(source: str) -> tuple[str, str] | None:
    m = re.match(r"^https?://github\.com/([^/\s]+)/([^/\s#?]+)", source or "")
    return (m.group(1), m.group(2)) if m else None


def upstream(owner: str, repo: str) -> dict | None:
    sha = gh(f"repos/{owner}/{repo}/commits/HEAD", "--jq", ".sha")
    if not sha:
        return None
    branch = gh(f"repos/{owner}/{repo}", "--jq", ".default_branch") or "?"
    lic = gh(f"repos/{owner}/{repo}/license", "--jq", ".license.spdx_id") or "none"
    return {"sha": sha, "branch": branch, "license": lic}


def read_pins(root: Path) -> dict[str, dict]:
    """Latest pin per REF id."""
    out: dict[str, dict] = {}
    f = root / PINS
    if f.exists():
        for line in f.read_text(encoding="utf-8").splitlines():
            if line.strip():
                rec = json.loads(line)
                out[rec["ref"]] = rec
    return out


def github_notes(root: Path) -> dict[str, tuple[str, str, str]]:
    out = {}
    for p in ref_notes(root):
        fm, _ = load(p)
        repo = github_repo(str(fm.get("source", "")))
        if repo:
            out[ref_id(p)] = (repo[0], repo[1], str(fm.get("source")))
    return out


def cmd_pin(root: Path, ids: str | None) -> int:
    notes = github_notes(root)
    wanted = [i.strip() for i in (ids or "").split(",") if i.strip()] or sorted(notes)
    recs = []
    for rid in wanted:
        if rid not in notes:
            print(f"skip {rid}: source is not a GitHub repository (organization pages and websites are not pinned)")
            continue
        owner, repo, _ = notes[rid]
        info = upstream(owner, repo)
        if not info:
            print(f"FAIL {rid}: could not read {owner}/{repo} through gh")
            continue
        rec = {"time": datetime.datetime.now().isoformat(timespec="seconds"), "ref": rid,
               "repo": f"{owner}/{repo}", **info}
        recs.append(rec)
        print(f"{rid}: {owner}/{repo} {info['branch']}@{info['sha'][:10]} licence {info['license']}")
    if recs:
        f = root / PINS
        f.parent.mkdir(parents=True, exist_ok=True)
        with f.open("a", encoding="utf-8") as fh:
            for rec in recs:
                fh.write(json.dumps(rec) + "\n")
    return 0 if recs else 1


def url_status(url: str) -> str:
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers={"User-Agent": "rg1-refs-drift"})
        try:
            with urllib.request.urlopen(req, timeout=10) as r:
                return str(r.status)
        except urllib.error.HTTPError as e:
            if method == "GET":
                return str(e.code)
        except (urllib.error.URLError, OSError, ValueError) as e:
            if method == "GET":
                return f"unreachable ({type(e).__name__})"
    return "unknown"


def cmd_drift(root: Path, links: bool) -> int:
    pins, notes = read_pins(root), github_notes(root)
    problems = 0
    for rid in sorted(notes):
        if rid not in pins:
            print(f"{rid}: never pinned (run `refs.py pin`)")
            problems += 1
            continue
        pin, owner_repo = pins[rid], pins[rid]["repo"].split("/")
        now = upstream(*owner_repo)
        if not now:
            print(f"{rid}: upstream unreachable through gh")
            problems += 1
        elif now["license"] != pin["license"]:
            print(f"{rid}: LICENCE CHANGED {pin['license']} -> {now['license']} (re-check rights before any adaptation)")
            problems += 1
        elif now["sha"] != pin["sha"]:
            print(f"{rid}: upstream moved {pin['sha'][:10]} -> {now['sha'][:10]} (pinned {pin['time'][:10]}); "
                  "the note's findings describe the pinned commit")
        else:
            print(f"{rid}: unchanged at {pin['sha'][:10]}")
    if links:
        for p in ref_notes(root):
            fm, _ = load(p)
            src = str(fm.get("source", ""))
            if src.startswith("http"):
                st = url_status(src)
                print(f"{ref_id(p)}: {st} {src}")
                problems += 0 if st.startswith(("2", "3")) else 1
    return 1 if problems else 0


# --------------------------------------------------------------------------- rights

def read_rights(root: Path) -> dict[str, dict]:
    f = root / RIGHTS
    return json.loads(f.read_text(encoding="utf-8")).get("notes", {}) if f.exists() else {}


def rights_gate(cls: str, use: str) -> tuple[bool, str]:
    if use == "method":
        return True, "methods and ideas may be restated in our own words; cite the note"
    if cls == "permissive-verified":
        return True, "licence verified; keep notices and record the file and commit in the task"
    why = {"permissive-claimed": "licence only claimed in the note; read the actual licence text, record it, and have jg confirm",
           "copyleft": "copyleft licence; no code or asset adaptation without jg's recorded decision",
           "platform-terms": "package and platform have separate terms; check the exact terms for this use",
           "per-item": "terms differ per resource or pack; verify the specific item",
           "unknown": "rights unverified",
           "reference-only": "retained as reference evidence; do not reuse its assets"}
    return False, why.get(cls, "unclassified")


def cmd_rights(root: Path, check: str | None, use: str) -> int:
    rights = read_rights(root)
    if check:
        if check not in rights:
            print(f"refs: no rights entry for {check}", file=sys.stderr)
            return 2
        ok, why = rights_gate(rights[check]["class"], use)
        print(f"{check} [{rights[check]['class']}] use={use}: {'ALLOWED' if ok else 'BLOCKED'}: {why}\nbasis: {rights[check]['basis']}")
        return 0 if ok else 1
    for p in ref_notes(root):
        rid = ref_id(p)
        e = rights.get(rid, {"class": "MISSING", "basis": ""})
        print(f"{rid:13} {e['class']:19} {e['basis']}")
    return 0


# --------------------------------------------------------------------------- ledger

def iso(ts: str) -> datetime.datetime:
    return datetime.datetime.fromisoformat(ts)


def task_cycle(t: dict) -> dict:
    hist = t.get("history", [])
    start = next((iso(h["time"]) for h in hist if h.get("to") == "in_progress"), None)
    review = next((iso(h["time"]) for h in hist if h.get("to") in ("review", "in_review")), None)
    return {"revisions": t.get("revisions", 0), "executions": len(t.get("executions", [])),
            "audits": len(t.get("audits", [])),
            "hours": round((review - start).total_seconds() / 3600, 1) if start and review else None}


def usage_tokens(root: Path) -> dict[str, int | None]:
    out: dict[str, int | None] = {}
    f = root / USAGE
    if f.exists():
        for line in f.read_text(encoding="utf-8").splitlines():
            if line.strip():
                r = json.loads(line)
                if r.get("tokens") is not None:
                    out[r["task"]] = (out.get(r["task"]) or 0) + r["tokens"]
                else:
                    out.setdefault(r["task"], None)
    return out


def cmd_ledger(root: Path, only: str | None) -> int:
    cites = cited_by(root)
    wanted = {i.strip() for i in (only or "").split(",") if i.strip()}
    task_refs: dict[str, set[str]] = {}
    for rid, tids in cites.items():
        if wanted and rid not in wanted:
            continue
        for tid in tids:
            task_refs.setdefault(tid, set()).add(rid)
    if not task_refs:
        print("no task cites a REF note yet (add `REF-…` IDs to the task note's **References:** line)")
        return 0
    queue = {t["id"]: t for t in task_store.load_tasks(root)}
    tokens, notes = usage_tokens(root), task_notes(root)
    print(f"{'task':10} {'status':12} {'rev':3} {'exec':4} {'aud':3} {'hours':6} {'tokens':8} floor-met (jg)   references")
    for tid in sorted(task_refs):
        t = queue.get(tid)
        if not t:
            print(f"{tid:10} has no task file")
            continue
        c = task_cycle(t)
        floor = "-"
        if tid in notes:
            m = re.search(r"(?im)reference floor met:\s*(.+)$", notes[tid].read_text(encoding="utf-8"))
            floor = m.group(1).strip()[:16] if m else "-"
        tok = tokens.get(tid)
        print(f"{tid:10} {t['status']:12} {c['revisions']:3} {c['executions']:4} {c['audits']:3} "
              f"{str(c['hours']) if c['hours'] is not None else 'n/a':6} {str(tok) if tok else 'n/a':8} {floor:17} "
              f"{', '.join(sorted(task_refs[tid]))}")
    print("Hours run from first start to first review; tokens are only what record-usage logged. Interview length and "
          "prompt count are not recorded by the queue: note them in the task. This is evidence for jg, not a verdict.")
    return 0


# --------------------------------------------------------------------------- review driver

SPEC = "02 Research/RSH-20261017-Reference-Automation-Spec.md"
OUTCOMES = {"keep": "keep as reference", "investigate": "investigate a specific gap",
            "experiment": "propose a scoped experiment", "unsuitable": "mark unsuitable for a stated use"}


def spec_section(root: Path, rid: str) -> str | None:
    f = root / SPEC
    if not f.exists():
        return None
    m = re.search(rf"(?ms)^### \d+\. {re.escape(rid)}\b.*?(?=^### |^## |\Z)", f.read_text(encoding="utf-8"))
    return m.group(0).strip() if m else None


def unchecked(root: Path) -> list[str]:
    return [rid for rid, done in review_checks(root).items() if not done]


def cmd_review_next(root: Path, only: str | None) -> int:
    notes = {ref_id(p): p for p in ref_notes(root)}
    queue = unchecked(root)
    rid = only or (queue[0] if queue else None)
    if not rid:
        print("every item in the Reference Review Index is checked")
        return 0
    if rid not in notes:
        print(f"refs: {rid} is not a REF note", file=sys.stderr)
        return 2
    p = notes[rid]
    fm, text = load(p)
    print(f"# Review packet: {rid} {fm.get('title', '')}  [{fm.get('status')}]")
    print(f"Note: {p.relative_to(root)}\nSource: {fm.get('source')}  (accessed {fm.get('accessed')})")
    print(f"Queue: {len(queue)} unchecked; this is {'the one you named' if only else 'next in Index order'}"
          + (f"; after it: {', '.join(queue[1:3])}" if not only and len(queue) > 1 else ""))
    r = read_rights(root).get(rid)
    if r:
        print(f"Rights class: {r['class']}: {r['basis']}")
    pin = read_pins(root).get(rid)
    if pin:
        print(f"Pinned: {pin['repo']}@{pin['sha'][:10]} on {pin['time'][:10]}, licence {pin['license']}")
    media = sorted(set(re.findall(r"!\[\[([^\]]+\.(?:mp4|jpg|jpeg|png))\]\]", text)))
    print(f"Media to open ({len(media)}): " + (", ".join(media[:12]) or "none (live source link only)"))
    for label, prefixes, limit in (("Identity", ("Identity",), 8), ("What was inspected", ("Observations", "Inspection"), 12),
                                   ("Intent (jg's words, do not edit)", ("Intent",), 14),
                                   ("Interpretation", ("Interpretation",), 10),
                                   ("Evidence to add", ("Experiment and evidence", "Future review", "Future evidence"), 6),
                                   ("Open questions", ("Open questions",), 8)):
        body = next((b for n, b in sections(text).items() if n.startswith(prefixes)), None)
        if body:
            print(f"\n## {label}\n{clip(body.strip(), limit)}")
    if any(n.startswith("Dense review") for n in sections(text)):
        print("\n(A 'Dense review' section already exists in the note.)")
    spec = spec_section(root, rid)
    if spec:
        print("\n## Proposed automations for this note (from the spec, unapproved)\n" + clip(spec, 30))
    print("\n## Decide with jg (Index, 'How to review one item')\n"
          "1. Open the real source (media above or the live link) before concluding anything.\n"
          "2. Name one concrete use, and what existing resources already cover it.\n"
          "3. jg picks: " + "; ".join(f"`{k}` = {v}" for k, v in OUTCOMES.items()) + ".\n"
          "4. Record with `refs.py decide` (needs: --outcome, --inspected, --unverified, --by jg; --next for investigate/experiment).")
    return 0


def cmd_decide(root: Path, rid: str, outcome: str, summary: str, inspected: str, unverified: str,
               nxt: str | None, by: str, apply: bool) -> int:
    notes = {ref_id(p): p for p in ref_notes(root)}
    if rid not in notes:
        print(f"refs: {rid} is not a REF note", file=sys.stderr)
        return 2
    if outcome in ("investigate", "experiment", "unsuitable") and not nxt:
        print(f"refs: --next is required for '{outcome}' (the next action, or the stated use it is unsuitable for)", file=sys.stderr)
        return 2
    if not by.strip():
        print("refs: --by is required: the decision is jg's", file=sys.stderr)
        return 2
    clean = lambda s: " ".join((s or "").replace("|", "/").split())  # noqa: E731
    today = datetime.date.today().isoformat()
    block = (f"## Review decision ({today})\n- **Outcome:** {OUTCOMES[outcome]}\n- **Decided by:** {clean(by)}\n"
             f"- **Summary:** {clean(summary)}\n- **Evidence inspected:** {clean(inspected)}\n"
             f"- **Still unverified:** {clean(unverified)}\n"
             + (f"- **Next action:** {clean(nxt)}\n" if nxt else "- **Next action:** none selected\n") + "\n")
    p = notes[rid]
    text = p.read_text(encoding="utf-8")
    anchor = next((m.start() for m in re.finditer(r"(?m)^## (Archived source video|Companion reference)\b", text)), None)
    new_text = (text[:anchor] + block + text[anchor:]) if anchor is not None else text.rstrip() + "\n\n" + block.rstrip() + "\n"
    new_text = re.sub(r"(?m)^updated: .*$", f"updated: {today}", new_text, count=1)
    idx, cat = root / INDEX, root / CATALOG
    idx_text = idx.read_text(encoding="utf-8") if idx.exists() else ""
    new_idx = re.sub(rf"(?m)^(\|\s*)\[ \](\s*\|\s*\[\[{re.escape(rid)})", r"\1[x]\2", idx_text, count=1)
    cat_text = cat.read_text(encoding="utf-8") if cat.exists() else ""
    tag = f" Review {today}: {OUTCOMES[outcome]}" + (f" ({clean(nxt)})" if outcome == "unsuitable" and nxt else "") + "."
    lines, new_cat, hit = cat_text.split("\n"), [], False
    for ln in lines:
        if not hit and ln.startswith("|") and re.search(rf"\[\[{re.escape(rid)}[^\]]*\]\]", ln):
            body = ln.rstrip().rstrip("|").rstrip()
            ln, hit = body + ("" if body.endswith((".", ";", ":")) else ".") + tag + " |", True
        new_cat.append(ln)
    print(f"{'APPLY' if apply else 'DRY RUN'}: {rid} -> {OUTCOMES[outcome]}")
    print(f"  note: append section, set updated {today}\n  index: {'tick' if new_idx != idx_text else 'no unchecked row found'}\n"
          f"  catalog: {'append review tag' if hit else 'no row found'}\n---\n{block.rstrip()}")
    if not apply:
        print("---\nRe-run with --apply once jg has confirmed this wording.")
        return 0
    p.write_text(new_text, encoding="utf-8")
    bump = lambda s: re.sub(r"(?m)^updated: .*$", f"updated: {today}", s, count=1)  # noqa: E731
    if new_idx != idx_text:
        idx.write_text(bump(new_idx), encoding="utf-8")
    if hit:
        cat.write_text(bump("\n".join(new_cat)), encoding="utf-8")
    return cmd_lint(root, None)


# --------------------------------------------------------------------------- actions

OUTCOME_SHORT = {"keep as reference": "keep", "investigate a specific gap": "investigate",
                 "propose a scoped experiment": "experiment", "mark unsuitable for a stated use": "unsuitable"}
BLOCKERS = [
    (r"when a game is chosen|a game choice|game and ability|game choice|which game", "a game choice"),
    (r"free studio", "a free Studio session"),
    (r"pads exist|studio vfx and surface pads|test pads", "the Studio test pads"),
    (r"uploading resource boy|before any upload|upload question|open question on uploading", "the Roblox-upload question"),
    (r"until reallusion|reallusion answers|reallusion confirms", "Reallusion's written answer"),
    (r"jg approves|jg's approval|jg approval|approved on its own|separate policy", "jg approval"),
]


def decision_blocks(text: str) -> list[dict]:
    """Every '## Review decision (date)' section as {date, outcome, next, summary}; latest last."""
    out = []
    for name, body in sections(text).items():
        m = re.match(r"Review decision \((\d{4}-\d{2}-\d{2})\)", name)
        if not m:
            continue
        fields = {k.lower(): v.strip() for k, v in re.findall(r"(?m)^- \*\*([^:*]+):\*\*\s*(.+)$", body)}
        out.append({"date": m.group(1), "outcome": fields.get("outcome", ""), "next": fields.get("next action", ""),
                    "decided_by": fields.get("decided by", "")})
    return sorted(out, key=lambda d: d["date"])


def blockers_of(next_action: str) -> list[str]:
    low = next_action.lower()
    return [label for pat, label in BLOCKERS if re.search(pat, low)]


def cmd_actions(root: Path, by_blocker: bool, only: str | None) -> int:
    rows = []
    for p in ref_notes(root):
        rid = ref_id(p)
        if only and rid != only:
            continue
        fm, text = load(p)
        blocks = decision_blocks(text)
        last = blocks[-1] if blocks else None
        outcome = OUTCOME_SHORT.get(last["outcome"], last["outcome"] or "?") if last else "no decision"
        nxt = last["next"] if last else ""
        rows.append({"id": rid, "status": str(fm.get("status", "?")), "outcome": outcome, "next": nxt,
                     "blockers": blockers_of(nxt) if last else [], "has_next": bool(nxt) and "none selected" not in nxt.lower()})
    if only and not rows:
        print(f"refs: {only} is not a REF note", file=sys.stderr)
        return 2
    if by_blocker:
        groups: dict[str, list[str]] = {}
        for r in rows:
            for b in r["blockers"]:
                groups.setdefault(b, []).append(r["id"])
        for b, ids in sorted(groups.items(), key=lambda kv: -len(kv[1])):
            print(f"{b} ({len(ids)}): {', '.join(ids)}")
        free = [r["id"] for r in rows if r["has_next"] and not r["blockers"]]
        print(f"next action recorded, no blocker named ({len(free)}): {', '.join(free) or '-'}")
        undecided = [r["id"] for r in rows if r["outcome"] == "no decision"]
        print(f"no decision yet ({len(undecided)}): {', '.join(undecided) or '-'}")
        return 0
    print(f"{'ID':13} {'status':9} {'outcome':12} waits on  |  next action")
    for r in rows:
        wait = "; ".join(r["blockers"]) or "-"
        print(f"{r['id']:13} {r['status']:9} {r['outcome']:12} {wait}  |  {r['next'][:110]}")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    sub.add_parser("trace")
    b = sub.add_parser("brief")
    b.add_argument("--category")
    b.add_argument("--task")
    b.add_argument("--ids")
    b.add_argument("--tier", choices=["light", "standard", "deep"], default="standard")
    b.add_argument("--max-lines", type=int, default=12)
    lt = sub.add_parser("lint")
    lt.add_argument("--file")
    g = sub.add_parser("guard")
    g.add_argument("--staged", action="store_true")
    g.add_argument("--base")
    n = sub.add_parser("new")
    n.add_argument("--area", required=True)
    n.add_argument("--title", required=True)
    n.add_argument("--dry-run", action="store_true")
    pn = sub.add_parser("pin")
    pn.add_argument("--ids")
    dr = sub.add_parser("drift")
    dr.add_argument("--links", action="store_true")
    rt = sub.add_parser("rights")
    rt.add_argument("--check")
    rt.add_argument("--use", choices=["code", "asset", "method"], default="code")
    ac = sub.add_parser("actions")
    ac.add_argument("--by-blocker", action="store_true")
    ac.add_argument("--id")
    rn = sub.add_parser("review-next")
    rn.add_argument("--id")
    dc = sub.add_parser("decide")
    dc.add_argument("id")
    dc.add_argument("--outcome", choices=sorted(OUTCOMES), required=True)
    dc.add_argument("--summary", required=True)
    dc.add_argument("--inspected", required=True)
    dc.add_argument("--unverified", required=True)
    dc.add_argument("--next")
    dc.add_argument("--by", required=True)
    dc.add_argument("--apply", action="store_true")
    lg = sub.add_parser("ledger")
    lg.add_argument("--refs")
    a = ap.parse_args(argv)
    root = a.root.resolve()
    if a.cmd == "list":
        return cmd_list(root)
    if a.cmd == "trace":
        return cmd_trace(root)
    if a.cmd == "brief":
        return cmd_brief(root, a.category, a.task, a.ids, a.tier, a.max_lines)
    if a.cmd == "lint":
        return cmd_lint(root, a.file)
    if a.cmd == "guard":
        return cmd_guard(root, a.staged, a.base)
    if a.cmd == "pin":
        return cmd_pin(root, a.ids)
    if a.cmd == "drift":
        return cmd_drift(root, a.links)
    if a.cmd == "rights":
        return cmd_rights(root, a.check, a.use)
    if a.cmd == "ledger":
        return cmd_ledger(root, a.refs)
    if a.cmd == "actions":
        return cmd_actions(root, a.by_blocker, a.id)
    if a.cmd == "review-next":
        return cmd_review_next(root, a.id)
    if a.cmd == "decide":
        return cmd_decide(root, a.id, a.outcome, a.summary, a.inspected, a.unverified, a.next, a.by, a.apply)
    return cmd_new(root, a.area, a.title, a.dry_run)


if __name__ == "__main__":
    sys.exit(main())
