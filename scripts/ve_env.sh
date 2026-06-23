#!/usr/bin/env bash
# VerilogEval-specific environment, sources the shared RTLLM env first.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/rtllm_env.sh"

VE_DATASET="$VE_ROOT/dataset_spec-to-rtl"
VE_RESULTS="$GENRTL_ROOT/experiments/results_verilogeval.csv"

export VE_DATASET VE_RESULTS
