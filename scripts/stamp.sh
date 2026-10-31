#!/usr/bin/env bash
# Writes the build stamp for a game's boot scripts and Studio check: BuildStamp.txt in the game's src/shared,
# which Rojo syncs as ReplicatedStorage.Shared.BuildStamp (gitignored). The git hooks run this after commit,
# checkout and merge with no argument (the active game). Run it by hand before a Play test if you've edited files
# since, so a "+dirty" stamp with a fresh time proves Rojo synced your latest code.
#
#   scripts/stamp.sh [--game <active slug>|haunted]    (default: the active game, scripts/active-game.env)
set -eu
cd "$(dirname "$0")/.."
. scripts/active-game.env
game="$ACTIVE_GAME_SLUG"
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
"$ACTIVE_GAME_SLUG") dir="$ACTIVE_GAME_ROOT" ;;
haunted) dir="archive/GAME-002-haunted-collector" ;;
*)
	echo "stamp: unknown game '$game' ($ACTIVE_GAME_SLUG or haunted)" >&2
	exit 2
	;;
esac
sha="$(git rev-parse --short HEAD 2>/dev/null || echo nogit)"
if [ -n "$(git status --porcelain -- "$dir" 2>/dev/null)" ]; then sha="$sha+dirty"; fi
printf '%s %s\n' "$sha" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$dir/src/shared/BuildStamp.txt"
cat "$dir/src/shared/BuildStamp.txt"
