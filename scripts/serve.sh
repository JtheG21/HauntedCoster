#!/usr/bin/env bash
# Starts Rojo for the active game (scripts/active-game.env). Always start Rojo with this: it refuses to run beside
# another server, so Studio can't end up synced to the wrong checkout. Run it outside any sandbox.
#
#   scripts/serve.sh [--port N] [--dry-run]    (default port 34872; --dry-run does the checks and doesn't serve)
#
# Exit 0 = served or dry run passed, 1 = another server is in the way, 2 = usage error.
set -u
cd "$(dirname "$0")/.."
. scripts/active-game.env

port=34872
dry_run=0
while [ $# -gt 0 ]; do
	case "$1" in
	--port)
		[ $# -ge 2 ] || { echo "serve: --port needs a value" >&2; exit 2; }
		port="$2"
		shift 2
		;;
	--dry-run)
		dry_run=1
		shift
		;;
	*)
		echo "serve: unknown argument: $1" >&2
		exit 2
		;;
	esac
done

describe() {
	local pid="$1" cwd
	cwd="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')"
	echo "  PID $pid in ${cwd:-<unknown cwd>}: $(ps -o args= -p "$pid")"
}

blockers=""
for pid in $(lsof -nP -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null); do blockers="$blockers $pid"; done
# Any other Rojo counts too: one server at a time, whatever its port (AGENTS.md "One Rojo server").
for pid in $(lsof -nP -c rojo -a -iTCP -sTCP:LISTEN -t 2>/dev/null); do
	case " $blockers " in *" $pid "*) ;; *) blockers="$blockers $pid" ;; esac
done
if [ -n "$blockers" ]; then
	echo "serve: refusing to start, something is already listening. Stop it first:" >&2
	for pid in $blockers; do describe "$pid" >&2; done
	exit 1
fi

scripts/stamp.sh >/dev/null
echo "serve: $ACTIVE_GAME_ID $ACTIVE_GAME_NAME, project $ACTIVE_GAME_PROJECT, port $port, from $(pwd -P)"
echo "serve: $(rojo --version). In Studio, open $ACTIVE_GAME_PLACE and connect one Rojo plugin of this same version."
echo "serve: stamp $(cat "$ACTIVE_GAME_ROOT/src/shared/BuildStamp.txt")"
if [ $dry_run -eq 1 ]; then
	exit 0
fi
exec rojo serve "$ACTIVE_GAME_PROJECT" --port "$port"
