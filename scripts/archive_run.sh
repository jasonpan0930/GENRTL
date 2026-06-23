#!/usr/bin/env bash
# Archive generated RTL to experiments/artifacts and update CSV.
set -euo pipefail
source "$(dirname "$0")/rtllm_env.sh"

WF="${1:?Usage: $0 <a|b> [model_name]}"
MODEL="${2:-}"

if [[ ! -f "$RUN_CONTEXT" ]]; then
  echo "Missing $RUN_CONTEXT — run scripts/prep_problem.sh first" >&2
  exit 1
fi

read -r INDEX ID PATH_REL TOP < <(python3 - <<PY
import json
c = json.load(open("$RUN_CONTEXT"))
print(c["problem_index"], c["problem_id"], c["rtllm_path"], c["top_module"])
PY
)

if [[ "$WF" == "a" ]]; then
  SKILL="rtl-workflow-a"
  SRC_DIR="$GENRTL_ROOT/workflow-a-direct/rtl"
  RTL_NAME="${TOP}.v"
elif [[ "$WF" == "b" ]]; then
  SKILL="rtl-pipeline-workflow-b"
  SRC_DIR="$GENRTL_ROOT/workflow-b-pipeline/rtl"
  RTL_NAME="${TOP}.v"
else
  echo "workflow must be a or b" >&2
  exit 1
fi

SRC="$SRC_DIR/$RTL_NAME"
if [[ ! -f "$SRC" ]]; then
  # fallback: any single .v in output dir
  SRC="$(find "$SRC_DIR" -maxdepth 1 -name '*.v' | head -1 || true)"
fi
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "No RTL found under $SRC_DIR (expected ${TOP}.v)" >&2
  python3 "$GENRTL_SCRIPTS/csv_update.py" \
    problem_index="$INDEX" workflow="$WF" problem_id="$ID" \
    rtllm_path="$PATH_REL" top_module="$TOP" skill="$SKILL" \
    gen_status=missing_rtl notes="archive_run: no rtl file"
  exit 1
fi

DEST_DIR="$ARTIFACTS_DIR/${ID}/workflow_${WF}"
mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST_DIR/$(basename "$SRC")"
ARCHIVED="experiments/artifacts/${ID}/workflow_${WF}/$(basename "$SRC")"

python3 "$GENRTL_SCRIPTS/csv_update.py" \
  problem_index="$INDEX" workflow="$WF" problem_id="$ID" \
  rtllm_path="$PATH_REL" top_module="$TOP" skill="$SKILL" \
  spec_path="spec/design.spec.txt" rtl_path="$SRC" rtl_archived="$ARCHIVED" \
  gen_status=archived ${MODEL:+model="$MODEL"}

echo "Archived -> $ARCHIVED"
