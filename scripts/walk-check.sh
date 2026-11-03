#!/usr/bin/env bash
# Opt-in hub walk-length estimate (scripts/hub_nav.py, tests/test_hub_walk.py).
#
# Informational; calibration failed twice (TASK-0130); Studio fresh-Play is the gate.
# The default scripts/check.sh skips the slow route estimate. Run this when you want the numbers:
#
#   scripts/walk-check.sh              route estimates (INFORMATIONAL lines) and the unit tests
#   scripts/walk-check.sh --calibrate  historical calibration (python3 tests/test_hub_walk.py --calibrate)

set -eu
root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"
if [ "${1:-}" = "--calibrate" ]; then
	exec python3 tests/test_hub_walk.py --calibrate
fi
HUB_WALK=1 exec python3 -m unittest discover -s tests -p 'test_hub_walk.py' -v
