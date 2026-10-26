#!/usr/bin/env bash
# Writes the build stamp for a game's boot scripts and Studio check: BuildStamp.txt in the game's src/shared,
# which Rojo syncs as ReplicatedStorage.Shared.BuildStamp (gitignored). The git hooks run this after commit,
# checkout and merge with no argument (GAME-002). Run it by hand before a Play test if you've edited files
# since, so a "+dirty" stamp with a fresh time proves Rojo synced your latest code.
#
#   scripts/stamp.sh [--game haunted|mathshow]    (default: haunted)
set -eu
cd "$(dirname "$0")/.."
game="haunted"
while [ $# -gt 0 ]; do
	case "$1" in
	--game)
		[ $# -ge 2 ] || { echo "stamp: --game needs a value" >&2; exit 2; }
		game="$2"
		shift 2
		;;
	*)
		echo "stamp: unknown argument: $1" >&2
		exit 2
		;;
	esac
done
case "$game" in
haunted | mathshow) ;;
*)
	echo "stamp: unknown game '$game' (haunted or mathshow)" >&2
	exit 2
	;;
esac
sha="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
if [ -n "$(git status --porcelain -- "games/$game" 2>/dev/null)" ]; then sha="$sha+dirty"; fi
printf '%s %s\n' "$sha" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "games/$game/src/shared/BuildStamp.txt"
cat "games/$game/src/shared/BuildStamp.txt"
