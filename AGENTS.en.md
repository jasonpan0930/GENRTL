# RTL Generation Project — Agent Guide

Compare **Workflow A** (direct SPEC→RTL) vs **Workflow B** (multi-stage pipeline).

## SPEC input

- Location: `spec/`
- Format: `.md` or `.txt` (prefer `design.spec.md`, else `design.spec.txt`, else the single spec file under `spec/`)
- SPEC may be written in Chinese or English
- **Do not** modify originals under `spec/`; Workflow B refined spec → `workflow-b-pipeline/spec_refined.md`
- **During generation**, do not read `RTLLM/`, `verified_*.v`, `testbench.v`, or `_chatgpt*` (see `.cursorignore`); run VCS evaluation only after RTL is produced

## Workflow A

- **Skill (recommended)**: `@rtl-workflow-a` (`SKILL.en.md`)
- Rule (auxiliary): `@workflow-a.en`
- Output: `workflow-a-direct/rtl/*.v`

## Workflow B

| Agent | Role | Output |
|-------|------|--------|
| Agent1 | Refine SPEC | `workflow-b-pipeline/spec_refined.md` |
| Agent2 | Timing / combinational·sequential plan | `workflow-b-pipeline/timing_plan.md` |
| Agent3 | RTL | `workflow-b-pipeline/rtl/*.v` |

Collaboration: `collaboration_log.md`, max 3 rounds. **Skill (recommended)**: `@rtl-pipeline-workflow-b` (`SKILL.en.md`)

## Experiments

Use the same `spec/` input for both workflows; log runs under `experiments/`
