# SPEC → RTL Experiment Project

Compare two Cursor Agent workflows that generate Verilog RTL from a hardware SPEC.

## Layout

| Path | Purpose |
|------|---------|
| `spec/` | Original SPEC (`.md` or `.txt`) |
| `workflow-a-direct/rtl/` | Workflow A: direct RTL output |
| `workflow-b-pipeline/` | Workflow B: refined spec, timing plan, collaboration log, RTL |
| `prompts/` | Copy-paste prompts (`*.zh.md` / `*.en.md`) |
| `.cursor/rules/` | Workflow A / B rules (`*.zh.mdc` / `*.en.mdc`) |
| `.cursor/skills/rtl-pipeline-workflow-b/` | Workflow B skill (`SKILL.zh.md` / `SKILL.en.md`) |

## Setup

1. Put your SPEC in `spec/` as `design.spec.md` or `design.spec.txt` (Chinese or English OK)
2. Open this folder in Cursor

## Workflow A

Copy `prompts/workflow-a.en.md`, or:

```
Run Workflow A per @workflow-a.en.
```

## Workflow B

Copy `prompts/workflow-b-full.en.md`, or:

```
Run Workflow B per @rtl-pipeline-workflow-b skill (read SKILL.en.md).
```

Staged: `workflow-b-agent1.en.md` → agent2 → agent3

## Experiments

See `experiments/README.en.md`

## Shared Verilog conventions

- Single `clk`; default `rst_n` active-low, synchronous release
- Filename = module name
- Annotate ports with SPEC section references
