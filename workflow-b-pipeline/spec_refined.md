# SPEC Refined — barrel_shifter

> Source: `spec/design.spec.txt` (RTLLM #29)
> Agent1 refinement with cycle-level timing, corner cases, and assumptions.

---

## §1 Overview

8-bit barrel shifter that rotates left by 0–7 positions based on a 3-bit
control signal. Implemented as three cascaded stages of 2-to-1 multiplexers
(`mux2X1`), each controlled by one bit of the control signal.

---

## §2 Interface

### Ports

| Signal | Direction | Width  | Description                               |
|--------|-----------|--------|-------------------------------------------|
| in     | input     | [7:0]  | 8-bit input data                          |
| ctrl   | input     | [2:0]  | 3-bit rotate amount control               |
| out    | output    | [7:0]  | 8-bit rotated output                      |

### Ordering (positional mapping)

Port declaration order **must** be preserved exactly: `in, ctrl, out`.

### Reset

No reset signal is defined. The design is purely combinational (no sequential
elements), so no reset is needed.

---

## §3 Submodule: mux2X1

### Ports

| Signal | Direction | Width | Description                                 |
|--------|-----------|-------|---------------------------------------------|
| a      | input     | 1     | Input 0 (selected when sel=0)               |
| b      | input     | 1     | Input 1 (selected when sel=1)               |
| sel    | input     | 1     | Select signal                               |
| out    | output    | 1     | Output: sel ? b : a                         |

### Behavior

```
out = sel ? b : a;
```

---

## §4 Timing & Handshakes

- **Combinational only**: no clock, no sequential elements, no handshake.
- Output is valid as soon as input stabilizes (propagation delay only).

---

## §5 Stage Structure

The design uses three cascaded mux stages. Each stage either passes the data
through unchanged or rotates left by a fixed amount.

### Stage 2 — Rotate by 4 (ctrl[2])

```
For each bit position i (0..7):
  s2_out[i] = ctrl[2] ? s1_in[(i+4) % 8] : s1_in[i]
where s1_in = in[7:0] (the top-level input to the chain).
```

### Stage 1 — Rotate by 2 (ctrl[1])

```
For each bit position i (0..7):
  s1_out[i] = ctrl[1] ? s2_out[(i+2) % 8] : s2_out[i]
```

### Stage 0 — Rotate by 1 (ctrl[0])

```
For each bit position i (0..7):
  out[i] = ctrl[0] ? s1_out[(i+1) % 8] : s1_out[i]
```

### Equivalent direct expression

```
For any ctrl value:
  shift_amount = ctrl[2]*4 + ctrl[1]*2 + ctrl[0]*1
  out[i] = in[(i + shift_amount) % 8]
```

---

## §6 Corner Cases

1. **ctrl = 0**: No rotation; out = in.
2. **ctrl = 7**: Rotate left by 7 positions (= rotate right by 1).
3. **All control bits independent**: Each bit controls one stage; the total
   rotation amount is the sum of the three stage amounts.
4. **No clock**: Design is purely combinational; output settles after
   propagation delay through three mux stages.
5. **Undefined / X on ctrl**: If any ctrl bit is X, the corresponding muxes
   output X on the relevant bits.

---

## §7 FSM

No FSM. Purely combinational.

---

## §8 Assumptions and Resolutions

- **[ASSUMPTION]** The operation is **rotate (wrap-around)**, not logical shift
  (zero-fill). The original SPEC says "rotating bits" (§Title) and "shifts or
  rotates" (§Function). We assume rotate because: (a) the title explicitly says
  "rotating bits", (b) a barrel shifter is canonically a rotator, and (c) the
  word "rotate" appears in the top-level description while "shift" in the
  implementation section describes the mechanism.
- **[ASSUMPTION]** The stage order is: ctrl[2] (shift by 4) → ctrl[1] (shift by
  2) → ctrl[0] (shift by 1), matching the bit order in the SPEC.
- **[ASSUMPTION]** All outputs are wires (combinational); no registers.

---

## §9 Diff vs Original SPEC

| Change | Description |
|--------|-------------|
| §2 Reset | Explicitly states no reset (purely combinational) |
| §3 mux2X1 | Extracted explicit port table and truth table |
| §5 Stage structure | Replaced prose with exact equations per stage |
| §6 Corner cases | New section |
| §7 FSM | Clarified no FSM |
| §8 Assumptions | Documented rotate vs shift ambiguity and stage order |
| Operation | Clarified as **rotate left with wrap-around** (not logical shift) |
