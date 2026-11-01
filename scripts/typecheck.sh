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
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
analyze() {
    project="$1"; shift
    rojo sourcemap "$project" -o "$tmp/map.json" >/dev/null || return 1
    # Preserve analyzer exit status, including a crash with no diagnostics.
    status=0
    out="$(luau-lsp analyze --sourcemap="$tmp/map.json" --definitions="$defs" --base-luaurc=.luaurc "$@" 2>&1)" || status=$?
    out="$(printf '%s' "$out" | grep -v '^\[INFO\]' || true)"
    if [ "$status" -ne 0 ] || [ -n "$out" ]; then
        echo "FAIL: $project analyzer exit=$status"
        echo "$out"
        return 1
    fi
}
analyze default.project.json src tests/luau || fail=1
analyze haunted.project.json games/haunted || fail=1
analyze hike-or-die.project.json games/hike-or-die/src || fail=1
[ "$fail" -eq 0 ] || exit 1
echo "no type errors (generated --!nocheck map excluded by its directive)"
