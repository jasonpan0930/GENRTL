---
name: rtl-pipeline-workflow-b
description: >-
  Workflow B multi-agent pipeline: refine SPEC (Agent1), timing/structure plan
  (Agent2, collaborates with Agent1), Verilog RTL (Agent3). Use when running
  Workflow B or Agent1/2/3; read this file (English).
---

# RTL Pipeline — Workflow B (English)

## Goal

Generate consistent Verilog without editing originals under `spec/`. SPEC may be Chinese or English; keep `spec_refined.md` in the same language as the source SPEC when possible.

## SPEC resolution

1. `spec/design.spec.md`
2. `spec/design.spec.txt`
3. The only `.md` / `.txt` under `spec/` (exclude `*.example`)

---

## Agent1 — Refine SPEC

**Output**: `workflow-b-pipeline/spec_refined.md`

1. Preserve all original requirements
2. Complete ports, widths, clock/reset, protocols, corner cases
3. Replace vague text with testable if/then items
4. Section **Assumptions and resolutions**: tag `[ASSUMPTION]`
5. Section **Diff vs original SPEC**
6. Section **Open for Agent2**: items affecting stage partitioning

**Forbidden**: Verilog; full `timing_plan` (interface timing constraints OK).

---

## Agent2 — Timing and structure

**Input**: `spec_refined.md` (may read `spec/` for reference; do not edit originals)

**Output**: `workflow-b-pipeline/timing_plan.md` (format: [reference.en.md](reference.en.md))

1. Stages 0, 1, 2, …
2. Per stage: `Combinational` | `Sequential` | `Mixed`
3. Inter-stage signals: name, width, registered?, handshakes
4. Per sequential block: clock edge, reset behavior
5. Top FSM if applicable

**Collaboration** (max 3 rounds, `collaboration_log.md`):

| Case | Action |
|------|--------|
| Conflicts with spec_refined | Log **Round N**, Issue / Proposed fix / Owner → update files + **Resolution** |
| Missing assumptions | Mark `[ASSUMPTION]` in plan; Agent1 updates spec next round |
| Aligned | **Status: ALIGNED** → proceed to Agent3 |

**Forbidden**: Verilog.

---

## Agent3 — RTL

**Read only**:

- `spec_refined.md`
- `timing_plan.md`
- `collaboration_log.md`

**Output**: `workflow-b-pipeline/rtl/*.v`

1. Module hierarchy matches `timing_plan.md`
2. Every sequential block maps to a plan stage
3. Ports match `spec_refined.md`
4. Comments cite Stage ID or spec section
5. If docs are insufficient: stop and list gaps; do not invent major architecture

**Verilog**: single `clk`; default `rst_n`; synthesizable; file name = module name.

---

## Full pipeline

```
spec/ → Agent1 → spec_refined.md → Agent2 → timing_plan.md
     → [collaboration ≤3 rounds] → ALIGNED → Agent3 → rtl/*.v
```

For single-agent requests, run only that section; do not skip prerequisites before Agent3.

## Subagents (optional)

For large designs, use Task subagents for Agent1/2; main chat merges log and runs Agent3.

## Report

Artifact paths, collaboration rounds, module list, remaining `[ASSUMPTION]` risks.
