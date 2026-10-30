#!/usr/bin/env bash
# Cheap deterministic checks. Run before any AI review. Exit code != 0 means fail.
#
#   scripts/check.sh            the required gate: the active game (scripts/active-game.env) and repo-wide checks
#   scripts/check.sh --archive  archived games only, on demand; not part of the gate
set -u
cd "$(dirname "$0")/.."
. scripts/active-game.env
mode="active"
case "${1:-}" in
"") ;;
--archive) mode="archive" ;;
*)
	echo "usage: scripts/check.sh [--archive]" >&2
	exit 2
	;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0
summary=""
# Runs one step quietly. Failure output prints straight away, so a `| tail -30` still ends on the summary lines.
step() {
	local name="$1" result="PASS"
	shift
	if "$@" >"$tmp/log" 2>&1; then
		if grep -q '^SKIP:' "$tmp/log"; then result="SKIP"; fi
	else
		result="FAIL"
		fail=1
		printf '\n== %s failed: %s\n' "$name" "$*"
		tail -40 "$tmp/log"
	fi
	summary+="$(printf '%-4s  %s' "$result" "$name")"$'\n'
}

json_files() {
	local f bad=0
	for f in "$@"; do
		python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" || { echo "invalid JSON: $f"; bad=1; }
	done
	return $bad
}

if [ "$mode" = "active" ]; then
	step "StyLua (format, $ACTIVE_GAME_ID)" stylua --check "$ACTIVE_GAME_ROOT"
	step "Selene (lint, $ACTIVE_GAME_ID)" selene "$ACTIVE_GAME_ROOT"
	step "Luau types (strict, $ACTIVE_GAME_ID)" scripts/typecheck.sh
	step "Unit specs (Lune, $ACTIVE_GAME_ID)" lune run scripts/lune/specs
	step "Rojo build ($ACTIVE_GAME_PROJECT)" rojo build "$ACTIVE_GAME_PROJECT" -o "$tmp/active.rbxl"
	step "JSON files" json_files "$ACTIVE_GAME_PROJECT" project-state.json tasks/queue.json "00 Studio/budget.json"
	step "Task queue (orchestrator)" python3 scripts/orchestrator.py validate
	step "Vault conventions" python3 scripts/validate_vault.py
	step "Reference notes" python3 scripts/refs.py lint
	step "Project skills" python3 scripts/skill_lint.py
	step "Python tests" python3 -m unittest discover -s tests -q
else
	for dir in archive/GAME-*/; do
		dir="${dir%/}"
		game="$(basename "$dir")"
		step "StyLua ($game)" stylua --check "$dir"
		step "Selene ($game)" selene "$dir"
		for project in "$dir"/*.project.json; do
			step "Rojo build ($game)" rojo build "$project" -o "$tmp/$game.rbxl"
		done
	done
	step "Luau types (archive)" scripts/typecheck.sh --archive
	step "Unit specs (Lune, GAME-002)" lune run scripts/lune/specs archive
	step "Unit specs (Lune, GAME-003)" sh -c 'cd archive/GAME-003-hike-or-die && lune run tests/lune/evidence-rules.spec.luau'
	step "Art codec (Python, GAME-002)" python3 -m unittest discover -s archive/GAME-002-haunted-collector/art -p 'test_*.py' -q
fi

printf '\n%s' "$summary"
if [ $fail -eq 0 ]; then echo "ALL CHECKS PASSED ($mode)"; else echo "CHECKS FAILED ($mode)"; fi
if [ "$mode" = "active" ]; then
	echo "Note: play scenarios and gameplay need Studio, see AGENTS.md \"Tests\". Archived games: scripts/check.sh --archive."
else
	echo "Note: GAME-001 specs need Studio, so they are not run here."
fi
exit $fail
