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

## Invocation (recommended)

User **@rtl-pipeline-workflow-b** runs this skill (default: full pipeline Agent1→2→collaboration→3). New chat, Pass@1.  
For a single stage, user says Agent1 / Agent2 / Agent3 only.

### RTLLM problem shorthand

User may say **`RTLLM #6`** or **`adder_pipe_64bit`**.

0. **At task start**, run: `source ~/source.sh`
1. If user gives `RTLLM #N` or id, **Agent runs** `./scripts/prep_problem.sh <N|id> --full-clean`
2. Read run context + SPEC; output `workflow-b-pipeline/rtl/<top_module>.v`
3. After RTL, **Agent runs** `./scripts/archive_run.sh b`
4. On **with eval**: **run** `./scripts/run_vcs.sh b`; report only; **Pass@1** forbids RTL edits from logs

Optional: `SPEC: spec/design.spec.txt` · `with eval`

## SPEC resolution

1. `spec/design.spec.md`
2. `spec/design.spec.txt`
3. The only `.md` / `.txt` under `spec/` (exclude `*.example`)

## Forbidden reads (Pass@1)

Do not read `RTLLM/`, `verified_*.v`, `testbench.v`, `_chatgpt35/`, `_chatgpt4/`. Use `[ASSUMPTION]` or stop; never copy from reference RTL.

## Domain knowledge

- Path: `workflow-b-pipeline/domain_knowledge.md` (English: `domain_knowledge.en.md`)
- **Agent1 / Agent2 / Agent3 must read before work**
- Add new conventions (declaration order, style, etc.) **only in that file**; reference from the skill
- **Agent3 must obey §1: declare every signal before use**

---

## Agent1 — Refine SPEC

**Output**: `workflow-b-pipeline/spec_refined.md`

1. Preserve all original requirements
2. Complete ports, widths, clock/reset, protocols, corner cases
3. **Reset signal (required; follow original SPEC — do not rename)**
   - Add a **Reset** subsection under **§2 Interface** and **§4 Timing**
   - **Port name** must match the original SPEC: if it says `rst`, keep `rst`; if `rst_n`, keep `rst_n`. **Never** swap `rst` ↔ `rst_n`
   - State explicitly: **polarity** (active-high / active-low), sync/async, register values when reset asserts/deasserts
   - If the original SPEC only says “reset” without polarity: document in `[ASSUMPTION]` but **keep the original port name**
   - Add a testable rule, e.g. use `negedge rst_n` only when the spec defines `rst_n` active-low
4. Replace vague text with testable if/then items
5. Section **Assumptions and resolutions**: tag `[ASSUMPTION]`
6. Section **Diff vs original SPEC**
7. **Cycle-level handshake timing for every valid/ready pair**
   For every handshake-based interface (opn_valid/res_ready, din_valid/dout_valid,
   etc.), specify **exactly**:
   - When the source asserts `*_valid` (which cycle, relative to what event)
   - How long `*_valid` stays asserted (single cycle? held until `*_ready`?)
   - When the sink asserts/deasserts `*_ready`
   - What happens if both valid and ready assert in the same cycle
   - **Deadlock prevention**: ensure no circular wait (`valid` waiting for `ready`
     while `ready` waits for `valid` across clock domains)

8. **FSM completeness: every state × every input**
   Enumerate the full transition table: for each state, list all input
   combinations and the resulting next state + output values.  Include a
   **default clause** for invalid state entries.

9. **Multi-output per-opcode enumeration**
   When the module has multiple status flags (zero, carry, negative, overflow,
   flag) and a control opcode:
   - For **each opcode**, state what **each** flag outputs.
   - Do NOT leave any flag as "don't care" or implicit — the testbench may
     check it.
   - If a flag is truly undefined for an opcode, state the safe default
     (0 / 1'bz / previous value).

   Example table template:

   | opcode | r       | zero | carry | negative | overflow | flag |
   |--------|---------|------|-------|----------|----------|------|
   | ADD    | a + b   | ...  | ...   | ...      | ...      | 1'bz |
   | SUB    | a - b   | ...  | ...   | ...      | ...      | 1'bz |

10. **Explicit corner-case section**
    Add a dedicated §**Corner cases** subsection:
    - For counters: behavior at min, max, and wrap-around.
    - For FSMs: behavior on invalid/reserved state vectors.
    - For arithmetic: overflow, underflow, division-by-zero, NaN/Inf.
    - For edge detectors: repeated toggling, missing edge, simultaneous edges.
    - For sequential circuits: reset assertion/deassertion timing relative to
      clock edges.

**Forbidden**: Verilog; full `timing_plan` (interface timing constraints OK).

---

## Agent2 — Timing and structure

**Input**: `spec_refined.md` (may read `spec/` for reference; do not edit originals)

**Output**: `workflow-b-pipeline/timing_plan.md` (format: [reference.en.md](reference.en.md))

1. Stages 0, 1, 2, …
2. Per stage: `Combinational` | `Sequential` | `Mixed`
3. Inter-stage signals: name, width, registered?, handshakes
4. Per sequential block: clock edge, reset (**same signal name and polarity as spec_refined §Reset; do not override `rst` with `rst_n` habit**)
5. Top FSM if applicable
6. Mark new signals as **new declarations** (align with `domain_knowledge.md` §1.4)

7. **Per combinational signal: write the exact Boolean/logic equation**
   For each combinational output in a stage, state its logic in explicit terms,
   not just "comparison result":

   - GOOD: `A_greater = (A[2] > B[2]) OR (A[2]==B[2] AND A[1]>B[1]) OR ...`
   - BAD:  `A_greater is high when A > B`

   This prevents Agent3 from introducing subtle logic errors in bit-level
   equations.

8. **Shift register bit-layout diagram (mandatory for division/multiplication)**
   When the design contains a shift register that holds compound state
   (e.g. partial remainder + quotient bits), **draw the exact bit indexing**:

   ```text
   SR = [remainder(8 bits)] [gap?1] [accumulated quotient(7 bits)]
         bit 15..8          bit 7    bit 6..0
   ```

   Specify per iteration:
   - Which bits feed into the trial subtraction
   - Where the new quotient bit is inserted
   - How the carry/underflow selects the next SR value

   Without this, Agent3 will guess the bit layout and likely get it wrong.

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
- `workflow-b-pipeline/domain_knowledge.md`

**Output**: `workflow-b-pipeline/rtl/*.v`

1. Module hierarchy matches `timing_plan.md`
2. Every sequential block maps to a plan stage
3. Ports match `spec_refined.md` (**including reset port name; never swap rst / rst_n**)
4. **Port order must match testbench expectation**: Many testbenches use
   **positional port mapping** (`.v` instance like `DUT(a, b, clk)` without named
   ports). Reordering ports changes the effective pinout. Follow the **original
   SPEC's port declaration order** exactly — do not sort alphabetically or by
   direction. If spec_refined adds ports, append them at the end; do not reorder
   existing ports.
5. **Prefer named port mapping** in generated RTL submodule instantiations:
   always use `.port_name(signal)`, never positional.
6. **Obey domain_knowledge §1: declare internal wire/reg before assign/always/instances; see that file for module order**
7. Comments cite Stage ID or spec section
8. If docs are insufficient: stop and list gaps; do not invent major architecture

**Verilog**: single `clk`; **reset per spec_refined** (name, polarity, sync behavior); do not default to `rst_n`; synthesizable; file name = module name.

**All modules in one file**: When the design has multiple modules, write all of them in
the single `<top_module>.v` file.
> Note: In normal development, one file per module is good practice. However, the
> testbench only reads one Verilog file (`${TEST_DESIGN}.v`), so keep every module
> in the same file. Put the top module first.

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
