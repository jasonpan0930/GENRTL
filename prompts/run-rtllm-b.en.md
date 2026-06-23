Run **Workflow B** (full pipeline) for one RTLLM problem:

1. User should run first: `./scripts/prep_problem.sh <index|id> --full-clean`
2. **@rtl-pipeline-workflow-b** `RTLLM #<index>`
3. Pass@1; read run context + SPEC; write all B artifacts + RTL
4. Output RTL: `workflow-b-pipeline/rtl/<top_module>.v`
5. Remind: `./scripts/archive_run.sh b` → `./scripts/run_vcs.sh b`
