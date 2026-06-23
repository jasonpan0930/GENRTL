---
name: rtl-workflow-a
description: >-
  Workflow A direct SPEC to Verilog RTL (Pass@1). Use when user runs Workflow A
  or @rtl-workflow-a; read this file (English).
---

# RTL Direct — Workflow A (English)

## Goal

Generate Verilog **in one pass** from the original SPEC under `spec/`. No refine or timing-plan stage. SPEC may be Chinese or English.

## Invocation (recommended)

User **@rtl-workflow-a** triggers this skill. Use a **new chat**, **Pass@1** (single generation; no VCS log feedback loop).

### RTLLM problem shorthand

User may say **`RTLLM #6`** or **`adder_pipe_64bit`**.

0. **At task start**, Agent runs in terminal: `source ~/source.sh` (VCS toolchain; our `scripts/*.sh` also auto-source)
1. If user gives `RTLLM #N` or problem id, **Agent runs** `./scripts/prep_problem.sh <N|id>` in terminal
2. Read `experiments/.run_context.json` and `spec/design.spec.txt`
3. Top module = `top_module`; output `workflow-a-direct/rtl/<top_module>.v`
4. After RTL, **Agent runs** `./scripts/archive_run.sh a`
5. If user says **with eval** or RTLLM batch default: **run** `./scripts/run_vcs.sh a`; report CSV outcome only
6. **Pass@1**: do not edit RTL based on VCS logs; do not read testbench/verified

Optional: `SPEC: spec/design.spec.txt` · `with eval`

## SPEC resolution order

1. `spec/design.spec.md`
2. `spec/design.spec.txt`
3. The **only** `.md` or `.txt` under `spec/` (exclude `*.example`)
4. If none found, report and stop

## Forbidden reads (Pass@1)

Do not read `RTLLM/`, `verified_*.v`, `testbench.v`, `_chatgpt35/`, `_chatgpt4/`.  
If ports or module name are missing: list gaps and stop, or tag `[ASSUMPTION]`; **never** fill from testbench or reference RTL.

## Outputs

| Allowed | Forbidden |
|---------|-----------|
| `workflow-a-direct/rtl/*.v` | Editing originals under `spec/` |
| | Writing under `workflow-b-pipeline/` |

- `module_name.v` matches module name in SPEC
- Top ports match SPEC; comment ports with SPEC section refs
- **Sequential / pipelined SPEC**: single `clk`; default `rst_n` active-low, synchronous deassert
- **Purely combinational SPEC** (no clock): do not add `clk`/`rst_n`
- Synthesizable; combinational logic in `always @(*)`; avoid latches
- Submodules may live in the same file as top (RTLLM often compiles only `top.v`)

## Flow

```
spec/ (read-only) → implement RTL → workflow-a-direct/rtl/*.v
```

## Done checklist

- [ ] All required top-level ports
- [ ] No obvious multi-drivers or unintended combinational loops
- [ ] List `[ASSUMPTION]` where SPEC is silent

## Report

SPEC path, `.v` files and module list, assumptions, and this run’s compile/sim summary from `experiments/results.csv`.  
**Pass@1**: do not revise RTL after VCS failure (Repair@k is a separate experiment).
