#!/usr/bin/env bash
# Points git at the versioned hooks in scripts/hooks (repo-local config; applies to all worktrees).
# Undo with: git config --unset core.hooksPath
set -eu
cd "$(dirname "$0")/.."
git config core.hooksPath scripts/hooks
scripts/stamp.sh
echo "hooks installed: $(ls scripts/hooks | tr '\n' ' ')"
