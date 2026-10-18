#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
if command -v node >/dev/null 2>&1; then
  runtime=node
elif [ -x /Users/jg/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node ]; then
  runtime=/Users/jg/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node
else
  echo 'Node.js 20+ is required for JavaScript checks.' >&2
  exit 1
fi
"$runtime" node_modules/prettier/bin/prettier.cjs --check src index.html tests/*.js tests/*.mjs scripts/*.mjs package.json
"$runtime" --check src/viewer.js
"$runtime" --check src/state.js
"$runtime" --test tests/*.test.js
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 scripts/library.py validate --dry-run
