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

Optional user line: `SPEC path: spec/design.spec.txt` (or actual filename).

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

SPEC path, `.v` files and module list, assumptions.  
**Do not** run VCS; user evaluates under RTLLM after generation.
