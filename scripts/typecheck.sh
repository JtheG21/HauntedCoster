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
if [ "${1:-}" = "--archive" ]; then
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	for dir in archive/GAME-*/; do
		game="$(basename "$dir")"
		cd "$root/$dir"
		rojo sourcemap ./*.project.json -o "$tmp/$game.json" >/dev/null
		out="$(luau-lsp analyze --sourcemap="$tmp/$game.json" --definitions="$defs" --base-luaurc="$root/.luaurc" src tests 2>&1 | grep -v '^\[INFO\]' || true)"
		if [ -n "$out" ]; then echo "$game:"; echo "$out"; fail=1; fi
	done
else
	rojo sourcemap "$ACTIVE_GAME_PROJECT" -o sourcemap.json >/dev/null
	out="$(luau-lsp analyze --sourcemap=sourcemap.json --definitions="$defs" --base-luaurc=.luaurc "$ACTIVE_GAME_ROOT" 2>&1 | grep -v '^\[INFO\]' || true)"
	if [ -n "$out" ]; then echo "$out"; fail=1; fi
fi
if [ $fail -ne 0 ]; then exit 1; fi
echo "no type errors"
