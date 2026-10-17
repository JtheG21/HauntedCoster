#!/usr/bin/env bash
# Claude Code PostToolUse hook (.claude/settings.json). After Claude edits a REF-* note under 10 References/,
# runs scripts/refs.py lint on it, using the checkout the file is in. Exit 2 shows the problems to Claude.
# The edit itself has already happened; this only reports. Tests: tests/test_claude_hooks.py
set -u

path="$(jq -r '.tool_input.file_path // empty')"
case "$path" in
*/10\ References/*/REF-*.md | */10\ References/*/*/REF-*.md) ;;
*) exit 0 ;;
esac
[ -f "$path" ] || exit 0
dir="$(dirname "$path")"
top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$top/scripts/refs.py" ] || exit 0

if ! out="$(python3 "$top/scripts/refs.py" --root "$top" lint --file "$path" 2>&1)"; then
	printf 'Reference lint found problems after this edit:\n%s\n' "$out" >&2
	exit 2
fi
exit 0
