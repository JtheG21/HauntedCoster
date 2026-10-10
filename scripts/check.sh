#!/usr/bin/env bash
# Cheap deterministic checks. Run before any AI review. Exit code != 0 means fail.
set -u
cd "$(dirname "$0")/.."
fail=0
step() { printf '\n== %s\n' "$1"; }
run() { if "$@"; then echo "PASS: $*"; else echo "FAIL: $*"; fail=1; fi; }

step "StyLua (format)";      run stylua --check src tests/luau
step "Selene (lint)";        run selene src tests/luau
step "Rojo build";           tmp="$(mktemp -d)"; run rojo build default.project.json -o "$tmp/check.rbxl"; rm -rf "$tmp"
step "JSON files";           for f in default.project.json project-state.json tasks/queue.json workflow/budget.json; do run python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f"; done
step "Task queue";           run python3 scripts/orchestrator.py validate
step "Python tests";         run python3 -m unittest discover -s tests -q

echo
if [ $fail -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; fi
echo "Note: Luau specs (tests/luau) and gameplay need Studio, see README."
exit $fail
