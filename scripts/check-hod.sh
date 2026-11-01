#!/usr/bin/env bash
# Same mandatory HOD gate locally and in CI. HOD_PYTHON may select a prepared venv.
set -eu
cd "$(dirname "$0")/.."
stylua --check games/hike-or-die
selene games/hike-or-die/src
lune run games/hike-or-die/tests/lune/evidence-rules.spec.luau
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
rojo build hike-or-die.project.json -o "$tmp/hod.rbxl"
"${HOD_PYTHON:-python3}" scripts/check_hod_map.py
