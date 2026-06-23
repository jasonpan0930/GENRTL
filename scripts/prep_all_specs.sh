#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/rtllm_env.sh"
cd "$GENRTL_ROOT"
python3 "$GENRTL_SCRIPTS/gen_manifest.py" >/dev/null
mkdir -p "$GENRTL_ROOT/spec/rtllm"

count=0
python3 - <<'PY' | while IFS='|' read -r id path_rel top; do
import sys
sys.path.insert(0, "scripts")
from manifest_lib import load_manifest
for p in load_manifest():
    print(f"{p['id']}|{p['path']}|{p['top_module']}")
PY
  src="$RTLLM_ROOT/$path_rel/design_description.txt"
  dst="$GENRTL_ROOT/spec/rtllm/${id}.spec.txt"
  cp "$src" "$dst"
  count=$((count + 1))
done

# recount properly
n=$(ls -1 "$GENRTL_ROOT/spec/rtllm"/*.spec.txt 2>/dev/null | wc -l)
echo "Copied $n specs to spec/rtllm/"
