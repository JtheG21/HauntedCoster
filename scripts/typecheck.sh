#!/usr/bin/env bash
# Luau type check (strict). Uses the Roblox type definitions downloaded by the VS Code Luau-LSP extension.
set -eu
cd "$(dirname "$0")/.."
defs="${LUAU_DEFS:-$HOME/Library/Application Support/Code/User/globalStorage/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau}"
if [ ! -f "$defs" ]; then
	# A skipped type check is not a pass. CI (or anyone who needs a real result) sets TYPECHECK_REQUIRED=1.
	if [ "${TYPECHECK_REQUIRED:-0}" = "1" ]; then echo "FAIL: Roblox type definitions not found and TYPECHECK_REQUIRED=1"; exit 1; fi
	echo "SKIP: Roblox type definitions not found (open the project in VS Code once). Types were NOT checked."
	exit 0
fi
fail=0
# GAME-001 (default.project.json). Its own sourcemap file, so sourcemap.json always stays GAME-002 for the editor.
rojo sourcemap default.project.json -o game001-sourcemap.json >/dev/null
out="$(luau-lsp analyze --sourcemap=game001-sourcemap.json --definitions="$defs" --base-luaurc=.luaurc src tests/luau 2>&1 | grep -v '^\[INFO\]' || true)"
if [ -n "$out" ]; then echo "$out"; fail=1; fi
# GAME-002 (haunted.project.json). Writes sourcemap.json, the file luau-lsp in VS Code reads.
rojo sourcemap haunted.project.json -o sourcemap.json >/dev/null
out="$(luau-lsp analyze --sourcemap=sourcemap.json --definitions="$defs" --base-luaurc=.luaurc games/haunted 2>&1 | grep -v '^\[INFO\]' || true)"
if [ -n "$out" ]; then echo "$out"; fail=1; fi
if [ $fail -ne 0 ]; then exit 1; fi
echo "no type errors"
