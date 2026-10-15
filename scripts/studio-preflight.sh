#!/usr/bin/env bash
# Studio and Rojo environment check. Run it before a Play test, scenario run or CrossPlot, and whenever a Studio
# run fails for no clear reason, instead of retrying. It catches what has cost the most retries on jg's 8 GB Mac:
# no Rojo server or several, a server for the wrong project (TEST-20261011-02) or the wrong checkout, extra
# Studio windows (2-player runs fail to start their second client), low memory, and Studio running stale code.
#
#   scripts/studio-preflight.sh [--root <checkout>]
#
#   --root   the checkout whose code is about to be tested (default: this script's checkout). Rojo must serve it.
#
# It changes nothing except the gitignored build stamp: it runs scripts/stamp.sh in that checkout and prints the
# value Studio must show at ReplicatedStorage.Shared.BuildStamp. The Studio-side checks (place, Edit or Play,
# stamp match) go through Studio MCP; see .claude/skills/studio-preflight/SKILL.md.
# Exit 0 = ready (warnings allowed), 1 = fix the FAIL lines first, 2 = usage error.

set -u

root="$(cd "$(dirname "$0")/.." && pwd -P)"
while [ $# -gt 0 ]; do
	case "$1" in
	--root)
		[ $# -ge 2 ] || { echo "studio-preflight: --root needs a value" >&2; exit 2; }
		root="$2"
		shift 2
		;;
	-h | --help)
		sed -n '2,14p' "$0"
		exit 0
		;;
	*)
		echo "studio-preflight: unknown argument: $1" >&2
		exit 2
		;;
	esac
done
if [ ! -f "$root/haunted.project.json" ]; then
	echo "studio-preflight: $root is not a Haunted Collector checkout (no haunted.project.json)" >&2
	exit 2
fi
root="$(cd "$root" && pwd -P)"

fails=0
ok() { echo "OK:   $1"; }
warn() { echo "WARN: $1"; }
fail() {
	echo "FAIL: $1"
	fails=$((fails + 1))
}

echo "studio-preflight: checkout under test: $root"

# Rojo servers. The rokit shim and the real binary both show up as "rojo serve"; keep only the outermost.
procs="$(ps -axo pid=,ppid=,command=)"
rojo_pids=" "
while read -r pid ppid exe sub _; do
	[ "$(basename "$exe" 2>/dev/null)" = "rojo" ] && [ "$sub" = "serve" ] && rojo_pids="$rojo_pids$pid "
done <<<"$procs"
servers=0
while read -r pid ppid exe sub args; do
	case "$rojo_pids" in *" $pid "*) ;; *) continue ;; esac
	case "$rojo_pids" in *" $ppid "*) continue ;; esac
	servers=$((servers + 1))
	project="default.project.json"
	port="34872"
	set -- $args
	while [ $# -gt 0 ]; do
		case "$1" in
		*.project.json) project="$1" ;;
		--port) [ $# -ge 2 ] && port="$2" ;;
		esac
		shift
	done
	cwd="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')"
	label="Rojo pid $pid: $project on port $port, serving ${cwd:-<unknown cwd>}"
	if [ "$(basename "$project")" != "haunted.project.json" ]; then
		fail "$label. That is not GAME-002: stop it, then run 'rojo serve haunted.project.json' in $root."
	elif [ -n "$cwd" ] && [ "$cwd" != "$root" ]; then
		fail "$label, not the checkout under test. Stop it and serve from $root, or pass --root $cwd if that is the code you mean to test."
	else
		ok "$label"
	fi
done <<<"$procs"
if [ $servers -eq 0 ]; then
	warn "no Rojo server: Studio won't get code changes. Start one with: cd \"$root\" && rojo serve haunted.project.json (or sync by hand and say so in the TEST note)."
elif [ $servers -gt 1 ]; then
	fail "$servers Rojo servers are running. Keep one, matched to its place (AGENTS.md \"One Rojo server\")."
fi

# Studio windows. Each open place is its own RobloxStudio process on macOS.
studios=0
while read -r exe args; do
	case "$exe" in */RobloxStudio.app/Contents/MacOS/RobloxStudio) ;; *) continue ;; esac
	studios=$((studios + 1))
	place="$(sed -n 's|.*-protocolString file://\([^ ]*\).*|\1|p' <<<"$args")"
	if [ -z "$place" ]; then
		asset="$(sed -n 's|.*assetid:\([0-9]*\).*|\1|p' <<<"$args")"
		place="${asset:+cloud place $asset}"
	fi
	echo "INFO: Studio window: ${place:-<no place in its launch arguments>}"
done <<<"$(ps -axo command=)"
if [ $studios -eq 0 ]; then
	warn "Roblox Studio is not running."
elif [ $studios -gt 1 ]; then
	warn "$studios Studio windows are open. Close the extras before a 2-player run; with several open, a run started through MCP can return nil."
else
	ok "one Studio window"
fi

# Memory (8 GB Mac; screen captures and CrossPlot drop the MCP connection when it runs low).
free="$(memory_pressure -Q 2>/dev/null | sed -n 's/.*percentage: \([0-9]*\)%.*/\1/p')"
if [ -z "$free" ]; then
	warn "couldn't read free memory (memory_pressure)."
elif [ "$free" -lt 20 ]; then
	warn "only $free% memory free: close other apps before CrossPlot or screen captures."
else
	ok "$free% memory free"
fi

# Build stamp: proves Studio runs this checkout's current code.
if [ -x "$root/scripts/stamp.sh" ]; then
	stamp="$("$root/scripts/stamp.sh" 2>/dev/null | tail -1)"
	echo "STAMP: Studio must show \"$stamp\" at ReplicatedStorage.Shared.BuildStamp (or in the boot line in Output). An older value means Rojo isn't syncing this checkout."
else
	warn "$root has no scripts/stamp.sh, so Studio's code can't be checked against it."
fi

if [ $fails -eq 0 ]; then
	echo "studio-preflight: READY"
	exit 0
fi
echo "studio-preflight: FIX FIRST ($fails failing)"
exit 1
