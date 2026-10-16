#!/usr/bin/env bash
# Art revision review: bake + export an asset, then render matched-camera comparison sheets of the baked game mesh
# and (for close-ups) the full-detail source, and check the triangle budget.
#
#   games/haunted/art/tools/review.sh <asset> [--glb] [--no-bake]
#
# Views come from review_views.json. Sheets land in ~/Roblox-Work/haunted/art/previews/review/<asset>_<sheet>_{bake,src}.png.
# --glb also writes the Studio import file (importing it is still jg's approved upload step).
set -euo pipefail
ASSET="${1:?usage: review.sh <asset> [--glb] [--no-bake]}"; shift
GLB=""; BAKE=1
for a in "$@"; do case "$a" in --glb) GLB="--glb";; --no-bake) BAKE=0;; *) echo "unknown option $a" >&2; exit 2;; esac; done
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
BL="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
OUT="$HOME/Roblox-Work/haunted/art/previews/review"; mkdir -p "$OUT"
CFG="$ROOT/games/haunted/art/tools/review_views.json"
cd "$ROOT"
if [ "$BAKE" = 1 ]; then
	"$BL" -b --factory-startup -P games/haunted/art/build.py -- --asset "$ASSET" --bake --export $GLB 2>&1 \
		| grep -E '^ASSET|Traceback|Error' | sed -E 's/.*("tris": [0-9]+, "tris_lod1": [0-9]+).*/\1/'
fi
python3 - "$CFG" "$ASSET" <<'PY' > "$OUT/.views"
import json, sys
cfg = json.load(open(sys.argv[1])).get(sys.argv[2])
if not cfg:
    sys.exit(f"no review views for {sys.argv[2]} in review_views.json")
for name, views in cfg["sheets"].items():
    print(cfg["ref"] + "\t" + name + "\t" + "\t".join(views))
PY
REF_ROOT="$ROOT"; [ -f "$ROOT/$(cut -f1 "$OUT/.views" | head -1)" ] || REF_ROOT="/Users/jg/Desktop/Rg1"  # concept art may live only in the main checkout
while IFS=$'\t' read -r ref name rest; do
	IFS=$'\t' read -r -a views <<< "$rest"
	args=(); for v in "${views[@]}"; do args+=(--view "$v"); done
	modes=(bake); [ "$name" != full ] && modes+=(src)
	for m in "${modes[@]}"; do
		flag=(); [ "$m" = bake ] && flag=(--bake)
		"$BL" -b --factory-startup -P games/haunted/art/tools/compare.py -- --asset "$ASSET" ${flag[@]+"${flag[@]}"} \
			--ref "$REF_ROOT/$ref" "${args[@]}" --out "$OUT/${ASSET}_${name}_${m}.png" 2>&1 | grep -E 'Traceback|Error' || true
		echo "sheet: $OUT/${ASSET}_${name}_${m}.png"
	done
done < "$OUT/.views"
rm -f "$OUT/.views"
python3 -m unittest tests.test_art_budgets 2>&1 | tail -1 | sed 's/^/budget: /'
