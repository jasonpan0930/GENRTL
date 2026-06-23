# RTLLM SPEC / testbench alignment

GENRTL copies `design_description.txt` → `spec/rtllm/*.spec.txt` and agents read **SPEC only** (Pass@1). VCS uses **testbench.v**. Both must agree on module name, ports, and `#()` parameters.

## Audit

```bash
python3 scripts/audit_spec_tb.py
```

Regenerate manifest + refresh spec copies after editing RTLLM:

```bash
./scripts/prep_all_specs.sh
```

## Fixes applied (2026-06-23)

| # | id | Change |
|---|-----|--------|
| 6 | `adder_pipe_64bit` | SPEC: added `Parameter` `DATA_WIDTH=64`, `STG_WIDTH=16` (TB already passed these) |
| 14 | `multi_pipe_4bit` | makefile: `TEST_DESIGN = multi_pipe_4bit` (was `multi_pipe`) |
| 17 | `fixed_point_substractor` | makefile: `TEST_DESIGN = fixed_point_subtractor` (was misspelled) |
| 25 | `sequence_detector` | SPEC: `reset_n` → `rst_n`; reset behavior text → active-low `rst_n` |
| 32 | `freq_divbyeven` | SPEC: module name `freq_diveven` → `freq_divbyeven` |

Manifest `top_module` is resolved as **testbench DUT → SPEC module name → makefile** (`scripts/rtllm_top_module.py`).

## Notes

- Folder name `fixed_point_substractor` is still misspelled; only makefile / `top_module` use `fixed_point_subtractor`.
- Positional TB instantiation (`alu`, `pe`, `float_multi`, `LFSR`): port names match SPEC; audit skips named-port compare.
- Do not edit RTLLM `verified_*.v` for Pass@1 experiments.
