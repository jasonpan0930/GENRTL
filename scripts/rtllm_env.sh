#!/usr/bin/env bash
# Shared paths for GENRTL batch scripts.
set -euo pipefail

GENRTL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENRTL_ROOT="$(cd "$GENRTL_SCRIPTS/.." && pwd)"
RTLLM_ROOT="${RTLLM_ROOT:-$GENRTL_ROOT/../RTLLM}"
VE_ROOT="${VE_ROOT:-$GENRTL_ROOT/../VerilogEval}"
MANIFEST="$GENRTL_ROOT/benchmarks/rtllm_manifest.yaml"
VE_MANIFEST="$GENRTL_ROOT/benchmarks/verilogeval_manifest.yaml"
RUN_CONTEXT="$GENRTL_ROOT/experiments/.run_context.json"
RESULTS_CSV="$GENRTL_ROOT/experiments/results.csv"
VE_RESULTS_CSV="$GENRTL_ROOT/experiments/results_verilogeval.csv"
ARTIFACTS_DIR="$GENRTL_ROOT/experiments/artifacts"
VE_ARTIFACTS_DIR="$GENRTL_ROOT/experiments/artifacts_verilogeval"

# VCS / Synopsys toolchain (workstation; may set SCRIPT_DIR — do not use that name here)
if [[ -f "$HOME/source.sh" ]]; then
  set +u
  # shellcheck disable=SC1090
  source "$HOME/source.sh"
  set -u
fi

# Re-resolve after source.sh (toolchain scripts may clobber generic names like SCRIPT_DIR)
GENRTL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENRTL_ROOT="$(cd "$GENRTL_SCRIPTS/.." && pwd)"

export GENRTL_SCRIPTS GENRTL_ROOT RTLLM_ROOT VE_ROOT MANIFEST VE_MANIFEST RUN_CONTEXT RESULTS_CSV VE_RESULTS_CSV ARTIFACTS_DIR VE_ARTIFACTS_DIR
