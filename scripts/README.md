# Batch RTLLM runs

## One problem, one workflow

```bash
# 1) Prepare SPEC + clean outputs (example: problem #6)
./scripts/prep_problem.sh 6
# or: ./scripts/prep_problem.sh adder_pipe_64bit

# 2) New Agent chat (Pass@1)
@rtl-workflow-a RTLLM #6
# or
@rtl-pipeline-workflow-b RTLLM #6

# 3) Archive RTL + update CSV
./scripts/archive_run.sh a
# or
./scripts/archive_run.sh b

# 4) VCS evaluate + update CSV
./scripts/run_vcs.sh a
./scripts/run_vcs.sh b
```

## CSV

All runs aggregate to **`experiments/results.csv`**.

## Copy all SPECs once

```bash
./scripts/prep_all_specs.sh   # -> spec/rtllm/<id>.spec.txt
```

## Environment

Default `RTLLM_ROOT` = `../RTLLM` (sibling of this repo). Override:

```bash
export RTLLM_ROOT=/path/to/RTLLM
```

VCS requires toolchain env. Scripts auto-run `source ~/source.sh` via `scripts/rtllm_env.sh`.  
Agents should also run `source ~/source.sh` at task start when using terminal.
