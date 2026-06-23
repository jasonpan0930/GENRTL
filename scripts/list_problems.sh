#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/rtllm_env.sh"
cd "$GENRTL_ROOT"
python3 - <<'PY'
import sys
from pathlib import Path
sys.path.insert(0, str(Path("scripts").resolve()))
from manifest_lib import load_manifest
print(f"{'#':>3}  {'id':<24}  top_module")
print("-" * 50)
for p in load_manifest():
    print(f"{p['index']:3d}  {p['id']:<24}  {p['top_module']}")
PY
