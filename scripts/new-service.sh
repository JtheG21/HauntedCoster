#!/usr/bin/env bash
# scripts/new-service.sh
# Stamps a Service, Config, Rules and spec for a game. Never overwrites existing files.
# Usage: scripts/new-service.sh <game> <Name>     e.g. scripts/new-service.sh mathshow Round
set -euo pipefail

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <game> <Name>" >&2
	exit 1
fi

GAME="$1"
NAME="$2"

if ! [[ "$NAME" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
	echo "error: Name must be PascalCase (got '$NAME')" >&2
	exit 1
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME_DIR="$ROOT/games/$GAME"

if [ ! -d "$GAME_DIR/src" ]; then
	echo "error: $GAME_DIR/src not found" >&2
	exit 1
fi

SERVICE="$GAME_DIR/src/server/Services/${NAME}Service.luau"
CONFIG="$GAME_DIR/src/shared/${NAME}Config.luau"
RULES="$GAME_DIR/src/shared/${NAME}Rules.luau"
SPEC="$GAME_DIR/tests/${NAME}Rules.spec.luau"

for f in "$SERVICE" "$CONFIG" "$RULES" "$SPEC"; do
	if [ -e "$f" ]; then
		echo "error: $f already exists; refusing to overwrite" >&2
		exit 1
	fi
done

mkdir -p "$(dirname "$SERVICE")" "$GAME_DIR/src/shared" "$GAME_DIR/tests"

cat >"$CONFIG" <<EOF
--!strict
-- Tunables for ${NAME}. Frozen: never mutate at runtime.

local ${NAME}Config = table.freeze({})

return ${NAME}Config
EOF

cat >"$RULES" <<EOF
--!strict
-- Pure ${NAME} logic. No Instances, no services, no yields: plain values in and out.

local ${NAME}Rules = {}

return ${NAME}Rules
EOF

cat >"$SERVICE" <<EOF
--!strict
-- ${NAME}Service: server-side ${NAME} state. Wires ${NAME}Rules + ${NAME}Config to the DataModel.

local ${NAME}Service = {}

local started = false

function ${NAME}Service.start(): ()
	if started then
		return
	end
	started = true
end

return ${NAME}Service
EOF

cat >"$SPEC" <<EOF
--!strict
local TestRunner = require(script.Parent.TestRunner)

return function(_t: TestRunner.T)
	-- TODO: boundary and edge-case tests for ${NAME}Rules
end
EOF

echo "created:"
echo "  ${SERVICE#"$ROOT"/}"
echo "  ${CONFIG#"$ROOT"/}"
echo "  ${RULES#"$ROOT"/}"
echo "  ${SPEC#"$ROOT"/}"
