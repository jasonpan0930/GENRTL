#!/usr/bin/env bash
# Prepare one RTLLM problem for @skill run: copy SPEC, write run context, clean outputs.
set -euo pipefail
source "$(dirname "$0")/rtllm_env.sh"

QUERY="${1:?Usage: $0 <index|problem_id> [--full-clean]}"
FULL_CLEAN=false
if [[ "${2:-}" == "--full-clean" ]]; then
  FULL_CLEAN=true
fi

PROBLEM_JSON="$(python3 "$GENRTL_SCRIPTS/lookup_problem.py" "$QUERY")"
INDEX="$(echo "$PROBLEM_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['index'])")"
ID="$(echo "$PROBLEM_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")"
PATH_REL="$(echo "$PROBLEM_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['path'])")"
TOP="$(echo "$PROBLEM_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['top_module'])")"

SRC="$RTLLM_ROOT/$PATH_REL/design_description.txt"
if [[ ! -f "$SRC" ]]; then
  echo "Missing SPEC: $SRC" >&2
  exit 1
fi

mkdir -p "$GENRTL_ROOT/spec/rtllm"
cp "$SRC" "$GENRTL_ROOT/spec/rtllm/${ID}.spec.txt"
cp "$SRC" "$GENRTL_ROOT/spec/design.spec.txt"

mkdir -p "$GENRTL_ROOT/workflow-a-direct/rtl" "$GENRTL_ROOT/workflow-b-pipeline/rtl"
find "$GENRTL_ROOT/workflow-a-direct/rtl" -maxdepth 1 -name '*.v' -delete
find "$GENRTL_ROOT/workflow-b-pipeline/rtl" -maxdepth 1 -name '*.v' -delete

if $FULL_CLEAN; then
  # domain_knowledge.md is project conventions — never delete here
  rm -f "$GENRTL_ROOT/workflow-b-pipeline/spec_refined.md" \
        "$GENRTL_ROOT/workflow-b-pipeline/timing_plan.md" \
        "$GENRTL_ROOT/workflow-b-pipeline/collaboration_log.md"
fi

mkdir -p "$(dirname "$RUN_CONTEXT")"
python3 - <<PY
import json
from pathlib import Path
ctx = {
  "problem_index": $INDEX,
  "problem_id": "$ID",
  "rtllm_path": "$PATH_REL",
  "top_module": "$TOP",
  "spec_path": "spec/design.spec.txt",
  "spec_archive": "spec/rtllm/${ID}.spec.txt",
  "rtllm_dir": "$RTLLM_ROOT/$PATH_REL",
}
Path("$RUN_CONTEXT").write_text(json.dumps(ctx, indent=2) + "\n")
PY

echo "Prepared problem #$INDEX ($ID)"
echo "  SPEC  -> spec/design.spec.txt"
echo "  Context -> experiments/.run_context.json"
echo "  Top module: $TOP"
echo ""
echo "Agent: @rtl-workflow-a RTLLM #$INDEX"
echo "   or: @rtl-pipeline-workflow-b RTLLM #$INDEX"
