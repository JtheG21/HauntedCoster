#!/usr/bin/env bash
# Luau type check (strict). Uses the Roblox type definitions downloaded by the VS Code Luau-LSP extension.
#
#   scripts/typecheck.sh            the active game (scripts/active-game.env); writes sourcemap.json, the file VS Code reads
#   scripts/typecheck.sh --archive  every archived game; sourcemaps go to a temp folder
set -eu
cd "$(dirname "$0")/.."
root="$(pwd -P)"
. scripts/active-game.env
defs="${LUAU_DEFS:-$HOME/Library/Application Support/Code/User/globalStorage/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau}"
if [ ! -f "$defs" ]; then
	# A skipped type check is not a pass. CI (or anyone who needs a real result) sets TYPECHECK_REQUIRED=1.
	if [ "${TYPECHECK_REQUIRED:-0}" = "1" ]; then echo "FAIL: Roblox type definitions not found and TYPECHECK_REQUIRED=1"; exit 1; fi
	echo "SKIP: Roblox type definitions not found (open the project in VS Code once). Types were NOT checked."
	exit 0
fi
fail=0
# Fails on any reported problem, and on a luau-lsp that exits non-zero without saying why.
analyze() {
	local raw out rc=0
	raw="$(luau-lsp analyze "$@" 2>&1)" || rc=$?
	out="$(grep -v '^\[INFO\]' <<<"$raw" || true)"
	if [ -n "$out" ]; then echo "$out"; return 1; fi
	if [ $rc -ne 0 ]; then echo "luau-lsp exited $rc with no output"; return 1; fi
}
if [ "${1:-}" = "--archive" ]; then
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	for dir in archive/GAME-*/; do
		game="$(basename "$dir")"
		cd "$root/$dir"
		rojo sourcemap ./*.project.json -o "$tmp/$game.json" >/dev/null
		echo "$game:"
		analyze --sourcemap="$tmp/$game.json" --definitions="$defs" --base-luaurc="$root/.luaurc" src tests || fail=1
	done
else
	rojo sourcemap "$ACTIVE_GAME_PROJECT" -o sourcemap.json >/dev/null
	analyze --sourcemap=sourcemap.json --definitions="$defs" --base-luaurc=.luaurc "$ACTIVE_GAME_ROOT" || fail=1
fi
if [ $fail -ne 0 ]; then exit 1; fi
echo "no type errors"
