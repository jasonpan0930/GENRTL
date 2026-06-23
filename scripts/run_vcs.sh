#!/usr/bin/env bash
# Run VCS for current (or given) problem and update experiments/results.csv.
set -euo pipefail
source "$(dirname "$0")/rtllm_env.sh"

WF="${1:?Usage: $0 <a|b> [index|problem_id]}"
QUERY="${2:-}"

if [[ -n "$QUERY" ]]; then
  "$GENRTL_SCRIPTS/prep_problem.sh" "$QUERY" >/dev/null
fi

if [[ ! -f "$RUN_CONTEXT" ]]; then
  echo "Missing run context. Run: scripts/prep_problem.sh <index>" >&2
  exit 1
fi

IFS='|' read -r INDEX ID PATH_REL TOP RTLLM_DIR < <(python3 - <<PY
import json
c = json.load(open("$RUN_CONTEXT"))
# Use | delimiter to handle spaces in PATH_REL and RTLLM_DIR
print(f'{c["problem_index"]}|{c["problem_id"]}|{c["rtllm_path"]}|{c["top_module"]}|{c["rtllm_dir"]}')
PY
)

if [[ "$WF" == "a" ]]; then
  SKILL="rtl-workflow-a"
  RTL_CANDIDATE="$GENRTL_ROOT/workflow-a-direct/rtl/${TOP}.v"
  ARCHIVED="$ARTIFACTS_DIR/${ID}/workflow_a/${TOP}.v"
elif [[ "$WF" == "b" ]]; then
  SKILL="rtl-pipeline-workflow-b"
  RTL_CANDIDATE="$GENRTL_ROOT/workflow-b-pipeline/rtl/${TOP}.v"
  ARCHIVED="$ARTIFACTS_DIR/${ID}/workflow_b/${TOP}.v"
else
  echo "workflow must be a or b" >&2
  exit 1
fi

if [[ -f "$ARCHIVED" ]]; then
  RTL_SRC="$ARCHIVED"
elif [[ -f "$RTL_CANDIDATE" ]]; then
  RTL_SRC="$RTL_CANDIDATE"
else
  RTL_SRC="$(find "$(dirname "$RTL_CANDIDATE")" -maxdepth 1 -name '*.v' 2>/dev/null | head -1 || true)"
fi

if [[ -z "$RTL_SRC" || ! -f "$RTL_SRC" ]]; then
  python3 "$GENRTL_SCRIPTS/csv_update.py" \
    problem_index="$INDEX" workflow="$WF" problem_id="$ID" \
    rtllm_path="$PATH_REL" top_module="$TOP" skill="$SKILL" \
    vcs_compile=skip vcs_sim=skip sim_message="no rtl to test"
  echo "No RTL to test" >&2
  exit 1
fi

PROB_DIR="$RTLLM_ROOT/$PATH_REL"
cp "$RTL_SRC" "$PROB_DIR/${TOP}.v"
cd "$PROB_DIR"

COMPILE=fail
SIM=skip
MSG=""

# RTLLM makefiles often omit -full64; 32-bit link fails on many Linux hosts (rmapats.so / libc headers).
make clean >/dev/null 2>&1 || rm -rf csrc simv simv.daidir *.log 2>/dev/null || true
if vcs -sverilog -full64 +v2k -timescale=1ns/1ns -debug_all \
  -l compile.log "${TOP}.v" testbench.v > /tmp/genrtl_vcs_compile.log 2>&1; then
  COMPILE=pass
  timeout 120 ./simv > /tmp/genrtl_vcs_sim.log 2>&1 || true
  if grep -qi "Your Design Passed" /tmp/genrtl_vcs_sim.log; then
    SIM=pass
    MSG="pass"
  elif grep -qE "failures|Error" /tmp/genrtl_vcs_sim.log; then
    SIM=fail
    MSG="$(grep -E 'failures|Error|Passed' /tmp/genrtl_vcs_sim.log | tail -1 | tr -d '\r')"
  else
    SIM=hang_or_unknown
    MSG="no pass/fail banner (possible hang)"
  fi
else
  MSG="$(tail -3 /tmp/genrtl_vcs_compile.log | tr '\n' ' ')"
fi

python3 "$GENRTL_SCRIPTS/csv_update.py" \
  problem_index="$INDEX" workflow="$WF" problem_id="$ID" \
  rtllm_path="$PATH_REL" top_module="$TOP" skill="$SKILL" \
  rtl_path="$RTL_SRC" vcs_compile="$COMPILE" vcs_sim="$SIM" sim_message="$MSG"

echo "Problem #$INDEX ($ID) workflow $WF — compile=$COMPILE sim=$SIM"
echo "$MSG"
