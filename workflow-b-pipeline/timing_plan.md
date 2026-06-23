# timing_plan.md — adder_bcd

## 1. Overview

- **Design name**: adder_bcd
- **Clock**: None — purely combinational.
- **Reset**: None — no sequential elements.
- **Dataflow one-liner**: `A, B, Cin` → binary addition → BCD correction → `Sum, Cout`

## 2. Hierarchy

| Module     | Type | Notes                |
|------------|------|----------------------|
| adder_bcd  | top  | Single module, no submodules |

## 3. Stages

### Stage 0 — BCD Add & Correct

- **Type**: `Combinational`
- **Module**: adder_bcd (top)
- **Function**: Add two BCD digits and carry-in; apply BCD correction.

#### Inputs

| Signal | Width | Source (stage/port) | Registered? |
|--------|-------|---------------------|-------------|
| A      | [3:0] | Port input          | No          |
| B      | [3:0] | Port input          | No          |
| Cin    | [1:0] | Port input          | No          |

#### Outputs

| Signal | Width | Destination    | Next cycle? |
|--------|-------|----------------|-------------|
| Sum    | [3:0] | Port output    | N/A (comb)  |
| Cout   | [1:0] | Port output    | N/A (comb)  |

#### Timing

- **Clock**: None
- **Reset**: None
- **Latency**: 0 cycles (combinational)

#### Combinational contents

1. **Binary addition**: `temp_sum[4:0] = A + B + Cin`

   Exact equation: `temp_sum = {1'b0, A} + {1'b0, B} + {4'd0, Cin}`  — 5-bit result.

2. **Correction detection**: `Cout = (temp_sum > 5'd9)`

   Equivalent bit-level equation:
   ```
   Cout = temp_sum[4]                          // bit 4 set => >= 16
        | (temp_sum[3] & temp_sum[2])          // 12-15
        | (temp_sum[3] & temp_sum[1]);         // 10-11
   ```
   (Covers all values 10–31 in one expression.)

3. **Correction addition**: `corrected_sum[4:0] = temp_sum + (Cout ? 5'd6 : 5'd0)`

4. **Sum output**: `Sum = corrected_sum[3:0]`

#### Handshake / backpressure

None. Outputs are always valid when inputs are stable.

## 4. Connectivity (ASCII)

```
A ──┐
     │
B ──┼──→ [ Stage0: Add & Correct ] ──→ Sum
     │                                  │
Cin ┘                                  Cout
```

## 5. FSM

None. The design has no state elements.

## 6. Alignment checklist

- [x] All ports assigned to top-level module (A, B, Cin, Sum, Cout)
- [x] No combinational loops (all signals flow forward: A/B/Cin → temp_sum → corrected_sum → Sum/Cout)
- [x] No latency assumptions needed (comb = 0 cycles)

## 7. Open items / risks

None. The design is straightforward and fully defined.
