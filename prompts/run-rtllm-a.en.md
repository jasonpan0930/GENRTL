Run **Workflow A** for one RTLLM problem:

1. User should run first: `./scripts/prep_problem.sh <index|id>`
2. **@rtl-workflow-a** `RTLLM #<index>` (or problem id)
3. Pass@1; read `experiments/.run_context.json` and `spec/design.spec.txt`
4. Output: `workflow-a-direct/rtl/<top_module>.v`
5. Remind: `./scripts/archive_run.sh a` → `./scripts/run_vcs.sh a`
