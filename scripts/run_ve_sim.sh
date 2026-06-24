#!/usr/bin/env bash
# Run VCS evaluation for VerilogEval problems and update results_verilogeval.csv.
# Usage: scripts/run_ve_sim.sh <a|b> [index]
set -euo pipefail
source "$(dirname "$0")/ve_env.sh"

WF="${1:?Usage: $0 <a|b> [index]}"
QUERY="${2:-}"

# If index given, look up problem info from manifest and write run context
# WITHOUT re-running prep_ve_problem.sh (which would delete generated RTL)
if [[ -n "$QUERY" ]]; then
  python3 - <<PY
import re, json
from pathlib import Path

query = "$QUERY"
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

q = query.lower()
found = None
if query.isdigit():
    idx = int(query)
    for p in problems:
        if p["index"] == idx:
            found = p
            break
else:
    for p in problems:
        if p["id"].lower() == q:
            found = p
            break
if found is None:
    raise SystemExit(f"Problem '{query}' not found in manifest")

idx = found["index"]
pid = found["id"]
tm = found.get("top_module", "TopModule")
prompt_file = f"$VE_DATASET/Prob{idx:03d}_{pid}_prompt.txt"
ref_file = f"$VE_DATASET/Prob{idx:03d}_{pid}_ref.sv"
test_file = f"$VE_DATASET/Prob{idx:03d}_{pid}_test.sv"

ctx = {
    "benchmark": "verilogeval",
    "problem_index": idx,
    "problem_id": pid,
    "top_module": tm,
    "prompt_file": prompt_file,
    "ref_file": ref_file,
    "test_file": test_file,
}
Path("$RUN_CONTEXT").parent.mkdir(parents=True, exist_ok=True)
Path("$RUN_CONTEXT").write_text(json.dumps(ctx, indent=2) + "\n")
print(f"Looked up problem #{idx} ({pid})")
PY
fi

if [[ ! -f "$RUN_CONTEXT" ]]; then
  echo "Missing run context. Run: scripts/prep_ve_problem.sh <index>" >&2
  exit 1
fi

IFS='|' read -r INDEX ID TOP_MODULE PROMPT_FILE REF_FILE TEST_FILE < <(python3 - <<PY
import json
c = json.load(open("$RUN_CONTEXT"))
if c.get("benchmark") != "verilogeval":
    raise SystemExit("Run context is not VerilogEval; use prep_ve_problem.sh first")
print('|'.join(str(c[k]) for k in ("problem_index","problem_id","top_module","prompt_file","ref_file","test_file")))
PY
)

# Determine RTL source
if [[ "$WF" == "a" ]]; then
  SKILL="rtl-workflow-a"
  RTL_CANDIDATE="$GENRTL_ROOT/workflow-a-direct/rtl/${TOP_MODULE}.v"
  ARTIFACT_VE="$VE_ARTIFACTS_DIR/${ID}/workflow_a/${TOP_MODULE}.v"
elif [[ "$WF" == "b" ]]; then
  SKILL="rtl-pipeline-workflow-b"
  RTL_CANDIDATE="$GENRTL_ROOT/workflow-b-pipeline/rtl/${TOP_MODULE}.v"
  ARTIFACT_VE="$VE_ARTIFACTS_DIR/${ID}/workflow_b/${TOP_MODULE}.v"
else
  echo "workflow must be a or b" >&2
  exit 1
fi

if [[ -f "$ARTIFACT_VE" ]]; then
  RTL_SRC="$ARTIFACT_VE"
elif [[ -f "$RTL_CANDIDATE" ]]; then
  RTL_SRC="$RTL_CANDIDATE"
else
  RTL_SRC="$(find "$(dirname "$RTL_CANDIDATE")" -maxdepth 1 -name '*.v' 2>/dev/null | head -1 || true)"
fi

if [[ -z "$RTL_SRC" || ! -f "$RTL_SRC" ]]; then
  python3 "$GENRTL_SCRIPTS/csv_update.py" \
    results_file="$VE_RESULTS" \
    problem_index="$INDEX" workflow="$WF" problem_id="$ID" \
    top_module="$TOP_MODULE" skill="$SKILL" \
    vcs_compile=skip vcs_sim=skip sim_message="no rtl to test"
  echo "No RTL to test" >&2
  exit 1
fi

# Run simulation in a temp directory
WORKDIR=$(mktemp -d "/tmp/genrtl_ve_${ID}_${WF}_XXXXXX")
trap "rm -rf $WORKDIR" EXIT

cp "$RTL_SRC" "$WORKDIR/${TOP_MODULE}.v"
cp "$REF_FILE" "$WORKDIR/ref_module.sv"
# Extend testbench timeout from #1000000 to #3000000 (some testbenches need more sim time)
sed 's/#1000000/#3000000/g' "$TEST_FILE" > "$WORKDIR/testbench.sv"
cd "$WORKDIR"

COMPILE=fail
SIM=skip
MSG=""

# VerilogEval testbench requires SystemVerilog (uses .* port connections, typedef, etc.)
if vcs -full64 -sverilog +v2k -timescale=1ps/1ps \
  -l compile.log \
  "${TOP_MODULE}.v" "ref_module.sv" "testbench.sv" \
  > /tmp/genrtl_ve_compile.log 2>&1; then
  COMPILE=pass
  timeout 120 ./simv > /tmp/genrtl_ve_sim.log 2>&1 || true
  
  if grep -q "TIMEOUT" /tmp/genrtl_ve_sim.log; then
    SIM=hang
    MSG="TIMEOUT (simulation exceeded cycle limit)"
  elif grep -qE "Mismatches:\s+0\s+in" /tmp/genrtl_ve_sim.log; then
    SIM=pass
    MSG="pass (no mismatches)"
  elif grep -qE "Mismatches:" /tmp/genrtl_ve_sim.log; then
    SIM=fail
    MISMATCH_LINE=$(grep -E "Mismatches:" /tmp/genrtl_ve_sim.log | tail -1 | tr -d '\r\n')
    HINT_LINE=$(grep -E "Hint:" /tmp/genrtl_ve_sim.log | grep -v "no mismatches" | tail -1 | tr -d '\r\n')
    MSG="${HINT_LINE} | ${MISMATCH_LINE}"
  else
    SIM=hang_or_unknown
    MSG="no pass/fail banner (possible hang)"
  fi
else
  MSG="$(tail -3 /tmp/genrtl_ve_compile.log | tr '\n' ' ' | tr -d '\r')"
fi

# Write to VerilogEval-specific CSV
mkdir -p "$(dirname "$VE_RESULTS")"
python3 "$GENRTL_SCRIPTS/csv_update.py" \
  results_file="$VE_RESULTS" \
  problem_index="$INDEX" workflow="$WF" problem_id="$ID" \
  top_module="$TOP_MODULE" skill="$SKILL" \
  rtl_path="$RTL_SRC" vcs_compile="$COMPILE" vcs_sim="$SIM" sim_message="$MSG"

echo "VerilogEval #$INDEX ($ID) workflow $WF — compile=$COMPILE sim=$SIM"
echo "$MSG"
