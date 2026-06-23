# RTLLM benchmark manifest

50 problems from RTLLM v2.0. Regenerate:

```bash
RTLLM_ROOT=../RTLLM python3 scripts/gen_manifest.py
```

| Field | Meaning |
|-------|---------|
| `index` | 1–50, use with `@skill RTLLM #N` |
| `id` | Directory name, e.g. `adder_pipe_64bit` |
| `path` | Relative path under `RTLLM/` |
| `top_module` | DUT module name (testbench instance → SPEC → makefile); RTL output basename |

List problems: `./scripts/list_problems.sh`

Audit SPEC vs testbench (module names, ports, parameters):

```bash
python3 scripts/audit_spec_tb.py
```
