# GENRTL — SPEC → RTL Experiment Project

Compare **Workflow A** (direct SPEC→RTL) vs **Workflow B** (multi-agent pipeline) using Cursor Agent, evaluated on [RTLLM](https://github.com/hkust-zhiyao/RTLLM) + VCS.

| Doc | Purpose |
|-----|---------|
| **[HANDOFF.md](HANDOFF.md)** | Progress, workstation setup, todos |
| [README.zh.md](README.zh.md) | 中文使用說明 |
| [README.en.md](README.en.md) | English guide |
| [AGENTS.md](AGENTS.md) | Agent index → `AGENTS.{zh,en}.md` |

## Quick start (Cursor)

1. **Open Folder** → this repo root (`myProject_GENRTL/`), not the parent `final_genrtl/`.
2. Put the benchmark text in `spec/design.spec.md` or `spec/design.spec.txt` (copy from RTLLM `design_description.txt`; do **not** use `*.example` filenames for runs).
3. New Agent chat, **Pass@1** (one generation, no VCS feedback to the agent):

| Workflow | Invoke |
|----------|--------|
| **A** — direct RTL | `@rtl-workflow-a` |
| **B** — refine → plan → RTL | `@rtl-pipeline-workflow-b` |

Optional one-liner: `SPEC: spec/design.spec.txt` · English skill → `SKILL.en.md` · 中文 → `SKILL.zh.md`

4. After RTL is generated, copy `workflow-*/rtl/<module>.v` to the RTLLM problem folder and run `make vcs && make sim` **outside** the agent (see [README.en.md](README.en.md#vcs-evaluation-rtllm)).

## Repository layout

| Path | Role |
|------|------|
| `spec/` | Original SPEC (read-only for agents) |
| `workflow-a-direct/rtl/` | Workflow A output |
| `workflow-b-pipeline/` | Workflow B artifacts + `rtl/` |
| `.cursor/skills/rtl-workflow-a/` | Workflow A skill |
| `.cursor/skills/rtl-pipeline-workflow-b/` | Workflow B skill |
| `.cursor/rules/` | Auxiliary path/fairness rules |
| `prompts/` | Optional short launchers (aligned with skills) |
| `experiments/` | Per-run logs |
| `.cursorignore` | Keep RTLLM / golden RTL out of index when applicable |

## Pass@1 fairness

During generation, agents must **not** read `RTLLM/`, `verified_*.v`, `testbench.v`, or `_chatgpt*`. See skills and `.cursor/rules/workflow-*.mdc`.

## Git

Remote: `git@github.com:jasonpan0930/GENRTL.git` (branch `main`)

**Typical commit for a framework release:** `.cursor/`, `.cursorignore`, `README*`, `HANDOFF`, `prompts/`, `AGENTS*`, templates.

**Per-run artifacts** (`spec/design.spec.txt`, `workflow-*/rtl/*.v`, filled `workflow-b-pipeline/*.md`) may be committed for reproducibility or kept local—document the run under `experiments/`.
