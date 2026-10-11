#!/usr/bin/env bash
# Luau type check (strict). Uses the Roblox type definitions downloaded by the VS Code Luau-LSP extension.
set -eu
cd "$(dirname "$0")/.."
defs="$HOME/Library/Application Support/Code/User/globalStorage/johnnymorganz.luau-lsp/globalTypes.PluginSecurity.d.luau"
if [ ! -f "$defs" ]; then echo "SKIP: Roblox type definitions not found (open the project in VS Code once)"; exit 0; fi
fail=0
# GAME-001 (default.project.json)
rojo sourcemap default.project.json -o sourcemap.json >/dev/null
out="$(luau-lsp analyze --sourcemap=sourcemap.json --definitions="$defs" --base-luaurc=.luaurc src tests/luau 2>&1 | grep -v '^\[INFO\]' || true)"
if [ -n "$out" ]; then echo "$out"; fail=1; fi
# GAME-002 (haunted.project.json)
rojo sourcemap haunted.project.json -o haunted-sourcemap.json >/dev/null
out="$(luau-lsp analyze --sourcemap=haunted-sourcemap.json --definitions="$defs" --base-luaurc=.luaurc games/haunted 2>&1 | grep -v '^\[INFO\]' || true)"
if [ -n "$out" ]; then echo "$out"; fail=1; fi
if [ $fail -ne 0 ]; then exit 1; fi
echo "no type errors"
