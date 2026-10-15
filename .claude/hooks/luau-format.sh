#!/usr/bin/env bash
# Claude Code PostToolUse hook (.claude/settings.json). After Claude edits a .luau file under the roots
# scripts/check.sh covers, formats it with StyLua and lints it with Selene, using the config of the checkout
# the file is in (main or any worktree). Same tools as the pre-commit hook, so commits stop failing on format.
# Exit 2 shows the problems to Claude. Tests: tests/test_claude_hooks.py
set -u

path="$(jq -r '.tool_input.file_path // empty')"
case "$path" in
*.luau) ;;
*) exit 0 ;;
esac
[ -f "$path" ] || exit 0
command -v stylua >/dev/null && command -v selene >/dev/null || exit 0

dir="$(dirname "$path")"
top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$top/stylua.toml" ] && [ -f "$top/selene.toml" ] || exit 0
rel="$(git -C "$dir" rev-parse --show-prefix)$(basename "$path")"
case "$rel" in
src/* | tests/luau/* | games/*) ;;
*) exit 0 ;; # third-party skills, maps and other files check.sh doesn't own
esac

cd "$top" || exit 0
if ! out="$(stylua "$rel" 2>&1)"; then
	printf 'StyLua could not format %s:\n%s\n' "$rel" "$out" >&2
	exit 2
fi
if ! out="$(selene --display-style quiet "$rel" 2>&1)"; then
	printf 'Selene found problems in %s (the pre-commit hook rejects warnings too):\n%s\n' "$rel" "$out" >&2
	exit 2
fi
exit 0
