#!/usr/bin/env bash
# Archive generated VerilogEval RTL to experiments/artifacts_verilogeval and update CSV.
set -euo pipefail
source "$(dirname "$0")/ve_env.sh"

WF="${1:?Usage: $0 <a|b> [model_name]}"
MODEL="${2:-}"

if [[ ! -f "$RUN_CONTEXT" ]]; then
  echo "Missing $RUN_CONTEXT — run scripts/prep_ve_problem.sh first" >&2
  exit 1
fi

read -r INDEX ID TOP_MODULE < <(python3 - <<PY
import json
c = json.load(open("$RUN_CONTEXT"))
if c.get("benchmark") != "verilogeval":
    raise SystemExit("Run context is not VerilogEval; use prep_ve_problem.sh first")
print(c["problem_index"], c["problem_id"], c["top_module"])
PY
)

if [[ "$WF" == "a" ]]; then
  SKILL="rtl-workflow-a"
  SRC_DIR="$GENRTL_ROOT/workflow-a-direct/rtl"
  RTL_NAME="${TOP_MODULE}.v"
elif [[ "$WF" == "b" ]]; then
  SKILL="rtl-pipeline-workflow-b"
  SRC_DIR="$GENRTL_ROOT/workflow-b-pipeline/rtl"
  RTL_NAME="${TOP_MODULE}.v"
else
  echo "workflow must be a or b" >&2
  exit 1
fi

SRC="$SRC_DIR/$RTL_NAME"
if [[ ! -f "$SRC" ]]; then
  SRC="$(find "$SRC_DIR" -maxdepth 1 -name '*.v' | head -1 || true)"
fi
if [[ -z "$SRC" || ! -f "$SRC" ]]; then
  echo "No RTL found under $SRC_DIR (expected ${TOP_MODULE}.v)" >&2
  python3 "$GENRTL_SCRIPTS/csv_update.py" \
    results_file="$VE_RESULTS" \
    problem_index="$INDEX" workflow="$WF" problem_id="$ID" \
    top_module="$TOP_MODULE" skill="$SKILL" \
    gen_status=missing_rtl notes="archive_ve_run: no rtl file"
  exit 1
fi

DEST_DIR="$VE_ARTIFACTS_DIR/${ID}/workflow_${WF}"
mkdir -p "$DEST_DIR"
cp "$SRC" "$DEST_DIR/$(basename "$SRC")"
ARCHIVED="experiments/artifacts_verilogeval/${ID}/workflow_${WF}/$(basename "$SRC")"

python3 "$GENRTL_SCRIPTS/csv_update.py" \
  results_file="$VE_RESULTS" \
  problem_index="$INDEX" workflow="$WF" problem_id="$ID" \
  top_module="$TOP_MODULE" skill="$SKILL" \
  spec_path="spec/design.spec.txt" rtl_path="$SRC" rtl_archived="$ARCHIVED" \
  gen_status=archived ${MODEL:+model="$MODEL"}

echo "Archived -> $VE_ARTIFACTS_DIR/${ID}/workflow_${WF}/"
