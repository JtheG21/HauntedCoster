#!/usr/bin/env bash
# Read-only GAME-001/002/003 environment and source check. See scripts/studio-preflight.md.
set -eu
exec python3 "$(dirname "$0")/studio_preflight.py" "$@"
