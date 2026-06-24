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

### Problem shorthand

User may say **`RTLLM #6`** or **`adder_pipe_64bit`**.
User may also say **`VerilogEval #1`** or **`zero`**; in that case top_module is always `TopModule`.

#### Common setup

0. **At task start**, run: `source ~/source.sh`

#### RTLLM flow

1. If user gives `RTLLM #N` or id, **Agent runs** `./scripts/prep_problem.sh <N|id> --full-clean`
2. Read run context + SPEC; output `workflow-b-pipeline/rtl/<top_module>.v`
3. After RTL, **Agent runs** `./scripts/archive_run.sh b`
4. On **with eval**: **run** `./scripts/run_vcs.sh b`; report only

#### VerilogEval flow

1. If user gives `VerilogEval #N` or id, **Agent runs** `./scripts/prep_ve_problem.sh <N|id> --full-clean`
2. Read run context + SPEC; output `workflow-b-pipeline/rtl/TopModule.v` (top_module is always `TopModule`)
3. After RTL, **Agent runs** `./scripts/archive_ve_run.sh b`
4. On **with eval**: **run** `./scripts/run_ve_sim.sh b <N>`; report only

#### Common rules

**Pass@1** forbids RTL edits from logs

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
   Enumerate the full transition table: for each state (including terminal /
   output-only states like DONE, DISC, FLAG, ERR, WAIT), list **all** input
   combinations and the resulting next state + output values.  Include a
   **default clause** for invalid state entries.

   **Critical — terminal-to-loop transitions**: For any state that transitions
   back to the main FSM loop (e.g. DONE → IDLE, DISC → S0), specify the
   next state **for each input value** — do not collapse into a single
   unconditional transition unless every input truly leads to the same state.
   A common bug: `DISC/FLAG → S0` regardless of `in`, when the spec
   requires `DISC → (in ? S1 : S0)`.

   **Output timing**: For every output signal, specify whether it is asserted
   in the **same cycle** as the triggering condition or in the **next cycle**.
   Use precise language: "asserted on the clock edge where the condition is
   met" vs. "asserted for one cycle starting one clock after the condition".

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

11. **FSM state parsimony — no invented intermediate states**
    Map FSM states **one-to-one** to the phases/steps described in the SPEC.
    Do not add extra states (e.g. a separate START state between start-bit
    detection and data reception) unless the SPEC explicitly requires a wait
    or a setup cycle. Every added state adds one cycle of latency — verify at
    cycle level that the state is necessary, not habitual.

    **Common anti-pattern**: SPEC says "detect the start bit, then wait for
    all 8 data bits" — the FSM should transition directly from IDLE to DATA
    (or IDLE → B0 → ... → B7). Do **not** insert `IDLE → START → DATA`.
    The start bit is sampled during the clock edge that triggers the IDLE→DATA
    transition; it does not own a separate state.

    **Litmus test**: for each proposed state, ask "what distinct behavior
    happens during this state that cannot happen during the previous or next
    state?" If the answer is "just preparation / bookkeeping", the state is
    likely spurious — merge it.

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

- `spec/design.spec.txt` (raw SPEC — cross-reference transitions and timing
  that may have been over-summarized in spec_refined)
- `spec_refined.md`
- `timing_plan.md`
- `collaboration_log.md`
- `workflow-b-pipeline/domain_knowledge.md`

**Resolution order**: `spec_refined.md` is the primary source for architecture
decisions. If spec_refined omits or over-summarizes a transition detail
(e.g. terminal-state fan-out, output timing), fall back to the raw SPEC to
fill the gap. `[ASSUMPTION]` any remaining ambiguity.

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
7. **Obey domain_knowledge §6.5: signals assigned inside `always` must be `reg`** (`nstate`, `next_state`, etc. — FSM combinational signals must never be `wire`; VCS reports IBLHS-NT)
8. Comments cite Stage ID or spec section
9. If docs are insufficient: stop and list gaps; do not invent major architecture

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
