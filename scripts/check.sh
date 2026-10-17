#!/usr/bin/env bash
# Cheap deterministic checks. Run before any AI review. Exit code != 0 means fail.
set -u
cd "$(dirname "$0")/.."
fail=0
step() { printf '\n== %s\n' "$1"; }
run() { if "$@"; then echo "PASS: $*"; else echo "FAIL: $*"; fail=1; fi; }

step "StyLua (format)";      run stylua --check src tests/luau games/haunted
step "Selene (lint)";        run selene src tests/luau games/haunted
step "Luau types";         run scripts/typecheck.sh
step "GAME-002 specs (Lune)"; run lune run scripts/lune/specs
step "Rojo build";           tmp="$(mktemp -d)"; run rojo build default.project.json -o "$tmp/check.rbxl"; run rojo build haunted.project.json -o "$tmp/haunted.rbxl"; rm -rf "$tmp"
step "JSON files";           for f in default.project.json haunted.project.json project-state.json tasks/queue.json "00 Studio/budget.json"; do run python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f"; done
step "Task queue";           run python3 scripts/orchestrator.py validate
step "Vault conventions";    run python3 scripts/validate_vault.py
step "Reference notes";      run python3 scripts/refs.py lint
step "Python tests";         run python3 -m unittest discover -s tests -q

echo
if [ $fail -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; fi
echo "Note: GAME-002 unit specs run headlessly above (Lune). GAME-001 specs, play scenarios and gameplay need Studio, see README."
exit $fail
