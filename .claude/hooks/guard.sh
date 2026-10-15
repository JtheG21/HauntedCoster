#!/usr/bin/env bash
# Claude Code PreToolUse hook (.claude/settings.json). Enforces AGENTS.md rules that were prose only:
# Git safety (LES-0006), one Rojo server matched to its place (TEST-20261011-02), no credentials,
# the do-not-edit folders, and the human gates on merging and publishing.
# Exit 2 blocks the call and shows stderr to Claude; an "ask" decision makes jg confirm it.
# It covers the common command forms, not every spelling. Tests: tests/test_claude_hooks.py
set -u

input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"

block() {
	echo "Blocked by .claude/hooks/guard.sh: $1" >&2
	exit 2
}
ask() {
	jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}'
	exit 0
}

# A command word: at the start of a line or after ; & | ( and optional spaces.
start='(^|[;&|(] *)'
git_cmd="${start}git( +-[Cc] +(\"[^\"]*\"|[^ ]+))* +"

if [ "$tool" = "Bash" ] && [ -n "$cmd" ]; then
	if grep -Eq "${git_cmd}(merge|rebase|reset|clean|cherry-pick|commit|push|pull|switch|checkout|restore|branch +-[dD])( |$)" <<<"$cmd" \
		&& ! grep -q 'scripts/preflight.sh' <<<"$cmd"; then
		block "state-changing Git needs the checkout guard first, in the same command: scripts/preflight.sh --root <checkout> --branch <name> && git -C <checkout> ... (AGENTS.md \"Git safety\", LES-0006)"
	fi
	if grep -Eq "${start}rojo +serve( |$)" <<<"$cmd" && ! grep -q '\.project\.json' <<<"$cmd"; then
		block "a bare 'rojo serve' serves GAME-001 (default.project.json). Use: rojo serve haunted.project.json (AGENTS.md \"One Rojo server\")"
	fi
	if grep -Eq "(^|[[:space:]<=/'\"])\.env([[:space:];|&)'\"]|$)" <<<"$cmd" && ! grep -Eq "${git_cmd}commit( |$)" <<<"$cmd"; then
		block "the command references .env, which holds credentials (AGENTS.md \"Safety rules\"). Use .env.example for key names; if you only mention the name, rephrase."
	fi
	if grep -Eq "${start}gh +pr +merge( |$)" <<<"$cmd"; then
		ask "Merging needs jg's explicit approval (AGENTS.md \"Safety rules\", 04 Agents/Workflow.md merge procedure)."
	fi
	if grep -Eq "${start}rojo +upload( |$)" <<<"$cmd"; then
		ask "rojo upload publishes to Roblox; publishing needs jg's explicit approval (AGENTS.md \"Safety rules\")."
	fi
fi

if [ -n "$path" ]; then
	name="$(basename "$path")"
	case "$name" in
	.env.example) ;;
	.env | .env.*) block "$name holds credentials; never read or print it (AGENTS.md \"Safety rules\"). Use .env.example for key names." ;;
	esac

	if [ "$tool" = "Edit" ] || [ "$tool" = "Write" ]; then
		# The path relative to its checkout (main or any worktree), resolved through the nearest existing folder.
		dir="$(dirname "$path")"
		rest="$name"
		while [ ! -d "$dir" ]; do
			rest="$(basename "$dir")/$rest"
			dir="$(dirname "$dir")"
		done
		top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
		if [ -n "$top" ] && [ -f "$top/haunted.project.json" ]; then
			rel="$(git -C "$dir" rev-parse --show-prefix)$rest"
			case "$rel" in
			Agents/* | Chats/* | .obsidian/*) block "$rel is on the do-not-edit list (AGENTS.md \"Project map\"): plugin data and settings." ;;
			"10 References/"*) ask "10 References/ stays unchanged during feature work unless jg asked for this edit (AGENTS.md \"Reference-first development\")." ;;
			esac
		fi
	fi
fi

exit 0
