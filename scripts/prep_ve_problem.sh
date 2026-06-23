#!/usr/bin/env bash
# Prepare one VerilogEval problem for @skill run.
# Usage: scripts/prep_ve_problem.sh <index> [--full-clean]
set -euo pipefail
source "$(dirname "$0")/ve_env.sh"

QUERY="${1:?Usage: $0 <index> [--full-clean]}"
FULL_CLEAN=false
if [[ "${2:-}" == "--full-clean" ]]; then
  FULL_CLEAN=true
fi

# Lookup from verilogeval manifest
MANIFEST_JSON="$(
python3 - <<PY
import re, json
from pathlib import Path
mf = Path("$VE_MANIFEST").read_text()
problems = []
cur = None
for line in mf.splitlines():
    m = re.match(r"\s+-\s+index:\s+(\d+)", line)
    if m:
        if cur: problems.append(cur)
        cur = {"index": int(m.group(1))}
        continue
    if cur is None: continue
    for key in ("id", "path", "top_module"):
        m2 = re.match(rf"\s+{key}:\s+(.+)", line)
        if m2:
            cur[key] = m2.group(1).strip()
if cur: problems.append(cur)

query = "$QUERY"
if query.isdigit():
    idx = int(query)
    for p in problems:
        if p["index"] == idx:
            print(json.dumps(p))
            break
else:
    q = query.lower()
    for p in problems:
        if p["id"].lower() == q:
            print(json.dumps(p))
            break
PY
)"

INDEX="$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['index'])")"
ID="$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")"
TOP_MODULE="$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['top_module'])")"

PROMPT_FILE="$VE_DATASET/Prob$(printf '%03d' $INDEX)_${ID}_prompt.txt"
REF_FILE="$VE_DATASET/Prob$(printf '%03d' $INDEX)_${ID}_ref.sv"
TEST_FILE="$VE_DATASET/Prob$(printf '%03d' $INDEX)_${ID}_test.sv"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Missing prompt: $PROMPT_FILE" >&2
  exit 1
fi
if [[ ! -f "$TEST_FILE" ]]; then
  echo "Missing testbench: $TEST_FILE" >&2
  exit 1
fi

# Copy SPEC to standard location
mkdir -p "$GENRTL_ROOT/spec/rtllm"
cp "$PROMPT_FILE" "$GENRTL_ROOT/spec/rtllm/${ID}.spec.txt"
cp "$PROMPT_FILE" "$GENRTL_ROOT/spec/design.spec.txt"

# Clean old RTL
mkdir -p "$GENRTL_ROOT/workflow-a-direct/rtl" "$GENRTL_ROOT/workflow-b-pipeline/rtl"
find "$GENRTL_ROOT/workflow-a-direct/rtl" -maxdepth 1 -name '*.v' -delete
find "$GENRTL_ROOT/workflow-b-pipeline/rtl" -maxdepth 1 -name '*.v' -delete

if $FULL_CLEAN; then
  rm -f "$GENRTL_ROOT/workflow-b-pipeline/spec_refined.md" \
        "$GENRTL_ROOT/workflow-b-pipeline/timing_plan.md" \
        "$GENRTL_ROOT/workflow-b-pipeline/collaboration_log.md"
fi

# Write run context
mkdir -p "$(dirname "$RUN_CONTEXT")"
python3 - <<PY
import json
from pathlib import Path
ctx = {
  "benchmark": "verilogeval",
  "problem_index": $INDEX,
  "problem_id": "$ID",
  "top_module": "$TOP_MODULE",
  "prompt_file": "$PROMPT_FILE",
  "ref_file": "$REF_FILE",
  "test_file": "$TEST_FILE",
  "spec_path": "spec/design.spec.txt",
  "spec_archive": "spec/rtllm/${ID}.spec.txt",
}
Path("$RUN_CONTEXT").write_text(json.dumps(ctx, indent=2) + "\n")
PY

echo "Prepared VerilogEval problem #$INDEX ($ID)"
echo "  SPEC  -> $PROMPT_FILE"
echo "  Test  -> $TEST_FILE"
echo "  Top module: $TOP_MODULE"
echo ""
echo "Agent: @rtl-workflow-a VerilogEval #$INDEX"
echo "   or: @rtl-pipeline-workflow-b VerilogEval #$INDEX"
