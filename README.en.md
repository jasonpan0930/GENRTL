# SPEC → RTL Experiment Project

Compare two Cursor Agent workflows that generate Verilog RTL from a hardware SPEC. Evaluation is intended with **RTLLM** + **VCS**.

## Layout

| Path | Purpose |
|------|---------|
| `spec/` | Original SPEC (`.md` or `.txt`) |
| `workflow-a-direct/rtl/` | Workflow A: direct RTL output |
| `workflow-b-pipeline/` | Workflow B: refined spec, timing plan, collaboration log, RTL |
| `.cursor/skills/rtl-workflow-a/` | Workflow A skill |
| `.cursor/skills/rtl-pipeline-workflow-b/` | Workflow B skill |
| `.cursor/rules/` | Auxiliary rules (paths, Pass@1 fairness) |
| `prompts/` | Optional short launchers (aligned with skills) |
| `experiments/` | Per-run logs |
| `.cursorignore` | Reduces indexing of RTLLM / golden RTL when applicable |

## Setup

1. Copy RTLLM `design_description.txt` to `spec/design.spec.md` or `spec/design.spec.txt` (not `*.example` filenames for real runs)
2. **Open Folder** → this repository root
3. **Agent mode**, **new chat** per run (Pass@1)

## Workflow A (recommended: @ skill only)

```
@rtl-workflow-a
```

Optional: `SPEC: spec/design.spec.txt`

Read `.cursor/skills/rtl-workflow-a/SKILL.en.md`. Output: `workflow-a-direct/rtl/*.v`

## Workflow B (recommended: @ skill only)

```
@rtl-pipeline-workflow-b
```

Full pipeline: Agent1 → Agent2 → (collaboration ≤3 rounds) → Agent3. Read `SKILL.en.md`.

Staged: say Agent1 / Agent2 / Agent3 only, or use `prompts/workflow-b-agent*.en.md`

## VCS evaluation (RTLLM)

After generation, **do not** ask the agent to simulate. In a terminal:

```bash
RTLLM=/path/to/RTLLM/Arithmetic/Adder/<problem_dir>
cp workflow-a-direct/rtl/<module>.v "$RTLLM/"   # or workflow-b-pipeline/rtl/
cd "$RTLLM" && make clean && make vcs && make sim
```

Many RTLLM testbenches use `[31:0]` and `clk`/`rst_n`; clarify in SPEC if the NL description uses `[32:1]`—still do not read `testbench.v` during generation.

## Pass@1 fairness

Do not read during generation: `RTLLM/`, `verified_*.v`, `testbench.v`, `_chatgpt*`. Use `[ASSUMPTION]` or stop if SPEC is incomplete.

## Experiments

See `experiments/README.en.md` (log model, skill, SPEC path, VCS result).

## Shared Verilog conventions

- **Sequential / pipelined SPEC**: single `clk`; default `rst_n` active-low, synchronous release
- **Purely combinational SPEC**: do not add `clk`/`rst_n`
- Filename = module name; annotate ports with SPEC section refs
