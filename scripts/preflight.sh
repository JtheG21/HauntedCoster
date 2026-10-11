#!/usr/bin/env bash
# Read-only Git checkout guard. Run it before any state-changing Git operation (switch, merge, rebase,
# cherry-pick, reset, clean, commit, push, branch deletion) and chain the operation with `&&`, so the
# operation never runs in the wrong checkout. It never changes anything.
#
#   scripts/preflight.sh --root <checkout> [--branch <name>] [--clean] [--allow <path>]...
#
#   --root     the checkout the operation must run in (required). Must exist and be a repo top level.
#   --branch   the branch that checkout must be on.
#   --clean    fail if that checkout has uncommitted changes (paths given with --allow are ignored).
#
# Example (merge in the dedicated main worktree, never in whatever directory is current):
#   scripts/preflight.sh --root "$MAIN_WT" --branch main --clean && git -C "$MAIN_WT" merge --no-ff ...
#
# Exit 0 = safe to proceed, 1 = mismatch (operation must not run), 2 = usage error.
# Why: a merge once ran in the main checkout because the intended worktree had been cleaned up
# (2026-10-10, TASK-0007 merge). See AGENTS.md "Git safety".

set -u

root=""
branch=""
clean=0
allow=()

while [ $# -gt 0 ]; do
	case "$1" in
	--root) root="${2:-}"; shift 2 ;;
	--branch) branch="${2:-}"; shift 2 ;;
	--clean) clean=1; shift ;;
	--allow) allow+=("${2:-}"); shift 2 ;;
	-h | --help) sed -n '2,17p' "$0"; exit 0 ;;
	*) echo "preflight: unknown argument '$1'" >&2; exit 2 ;;
	esac
done

if [ -z "$root" ]; then
	echo "preflight: --root is required (name the checkout explicitly; never rely on the current directory)" >&2
	exit 2
fi

fail() {
	echo "PREFLIGHT FAILED: $1" >&2
	echo "Stop. Re-discover the correct checkout; do not run the operation anywhere else." >&2
	exit 1
}

# 1. The checkout must exist. A missing directory is the original failure: never fall back.
[ -d "$root" ] || fail "checkout '$root' does not exist (cleaned up or never created)"

# Resolve symlinks (macOS /tmp -> /private/tmp) so the comparison is exact.
want=$(cd "$root" 2>/dev/null && pwd -P) || fail "cannot enter '$root'"
top=$(git -C "$want" rev-parse --show-toplevel 2>/dev/null) || fail "'$root' is not inside a Git repository"
top=$(cd "$top" && pwd -P)

# 2. It must be the top level of that checkout, not a subfolder of some other checkout.
[ "$top" = "$want" ] || fail "'$root' is inside checkout '$top', not a checkout itself"

current=$(git -C "$want" branch --show-current)
status=$(git -C "$want" status --porcelain)

echo "preflight: root=$want"
echo "preflight: branch=${current:-<detached>}"

# 3. Branch must match.
if [ -n "$branch" ] && [ "$current" != "$branch" ]; then
	fail "checkout is on '${current:-<detached>}', expected '$branch'"
fi

# 4. Optionally clean, ignoring explicitly allowed paths (e.g. a user's own scratch file).
if [ "$clean" = 1 ] && [ -n "$status" ]; then
	dirty=""
	while IFS= read -r line; do
		path="${line:3}"
		path="${path#\"}"
		path="${path%\"}"
		skip=0
		for a in "${allow[@]+"${allow[@]}"}"; do
			[ "$path" = "$a" ] && skip=1
		done
		[ "$skip" = 1 ] || dirty="$dirty$line"$'\n'
	done <<<"$status"
	if [ -n "$dirty" ]; then
		printf '%s' "$dirty" >&2
		fail "checkout has uncommitted changes"
	fi
fi

echo "preflight: OK"
exit 0
