#!/usr/bin/env bash
# Shared paths for GENRTL batch scripts.
set -euo pipefail

GENRTL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENRTL_ROOT="$(cd "$GENRTL_SCRIPTS/.." && pwd)"
RTLLM_ROOT="${RTLLM_ROOT:-$GENRTL_ROOT/../RTLLM}"
MANIFEST="$GENRTL_ROOT/benchmarks/rtllm_manifest.yaml"
RUN_CONTEXT="$GENRTL_ROOT/experiments/.run_context.json"
RESULTS_CSV="$GENRTL_ROOT/experiments/results.csv"
ARTIFACTS_DIR="$GENRTL_ROOT/experiments/artifacts"

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

export GENRTL_SCRIPTS GENRTL_ROOT RTLLM_ROOT MANIFEST RUN_CONTEXT RESULTS_CSV ARTIFACTS_DIR
