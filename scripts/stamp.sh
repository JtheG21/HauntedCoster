#!/usr/bin/env bash
# Writes the build stamp the GAME-002 boot scripts print (games/haunted/src/shared/BuildInfo.luau).
# The git hooks run this after commit, checkout and merge. Run it by hand before a Play test if you've
# edited files since, so a "+dirty" stamp with a fresh time proves Rojo synced your latest code.
set -eu
cd "$(dirname "$0")/.."
sha="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
if [ -n "$(git status --porcelain -- games/haunted 2>/dev/null)" ]; then sha="$sha+dirty"; fi
printf '%s %s\n' "$sha" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > games/haunted/src/shared/BuildStamp.txt
cat games/haunted/src/shared/BuildStamp.txt
