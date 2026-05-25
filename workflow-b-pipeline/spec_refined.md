# Refined Specification — 64-bit Pipelined Ripple-Carry Adder

## 1. Overview

Design a **64-bit ripple-carry adder** (`adder_pipe_64bit`) implemented as a **multi-stage pipeline**. Partial sums and inter-stage carries are computed in segmented ripple fashion; pipeline registers (clocked by `clk`, cleared by active-low `rst_n`) hold operands, partial results, carry bits, and a delayed enable chain. The final **65-bit** sum appears on `result` when `o_en` is asserted.

## 2. Interface (Ports)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | Rising-edge clock for all sequential elements |
| `rst_n` | input | 1 | Active-low asynchronous reset; when low, clears pipeline and deasserts `o_en` |
| `i_en` | input | 1 | Launch enable: when high on a rising `clk` edge, accepts `adda`/`addb` into the pipeline |
| `adda` | input | 64 | Operand A |
| `addb` | input | 64 | Operand B |
| `result` | output | 65 | `{carry_out, sum[63:0]}` of `adda + addb` |
| `o_en` | output | 1 | High when `result` is valid for the operation launched by a prior `i_en` |

**Module name**: `adder_pipe_64bit`

## 3. Functional requirements (testable items)

### 3.1 Reset

- **R1**: When `rst_n` is low, on the next active clock edge (or asynchronously for registered outputs per implementation choice documented in timing plan), `o_en` shall be **0** and internal pipeline state shall be cleared so no stale valid is implied.
- **R2**: When `rst_n` deasserts high, the module shall be idle until `i_en` launches an operation.

### 3.2 Launch (`i_en`)

- **R3**: When `i_en` is **1** at a rising edge of `clk` and `rst_n` is high, the module shall capture `adda` and `addb` presented in that cycle and start a pipelined addition.
- **R4**: When `i_en` is **0**, the module shall **not** capture new operands at that edge; operations already in the pipeline shall continue to completion.
- **R5**: `i_en` is assumed **one cycle wide** per launched operation (pulse). Holding `i_en` high for multiple consecutive cycles launches **independent** operations each cycle (throughput = 1 op/cycle after fill).

### 3.3 Addition semantics

- **R6**: For a launched operation, `result` shall equal unsigned `adda + addb` as a 65-bit value: `result[63:0]` is the sum bit vector; `result[64]` is the carry-out (MSB).
- **R7**: Addition is **unsigned** binary ripple-carry across four **16-bit** segments (see §4).

### 3.4 Output valid (`o_en`)

- **R8**: `o_en` shall be **1** on the cycle where the corresponding `result` for that operation is stable and reflects the sum of the captured operands.
- **R9**: `o_en` shall be **0** when no completed result is presented (reset, idle, or between result epochs if applicable).
- **R10**: `o_en` shall be delayed from the launching `i_en` by a fixed pipeline latency **L** cycles (see §4).

### 3.5 Operand timing

- **R11**: `adda` and `addb` must be stable in the cycle where `i_en` is sampled high.

## 4. Timing and performance

| Parameter | Value |
|-----------|-------|
| Pipeline depth | **4** stages (16-bit ripple segments) |
| Latency **L** | **4** clock cycles from launch (`i_en` high) to `o_en` high with valid `result` |
| Throughput (steady state) | One 64-bit add per clock after pipeline fill |
| Clock | Single `clk`, rising-edge active |
| Reset | `rst_n` active low |

**Segmentation (ripple between stages)**:

| Segment | Bit range | Receives carry from |
|---------|-----------|---------------------|
| 0 | [15:0] | 0 (implicit) |
| 1 | [31:16] | segment 0 |
| 2 | [47:32] | segment 1 |
| 3 | [63:48] | segment 2; produces `result[64]` |

## 5. Assumptions and resolutions

- **[ASSUMPTION] A1**: Four pipeline stages of 16 bits each — original SPEC says "several" stages without a count; four is a standard partition for 64-bit datapaths.
- **[ASSUMPTION] A2**: `i_en` is a one-cycle pulse per operation; continuous `i_en` launches back-to-back ops (pipelined valid on `o_en` tracks via enable shift register).
- **[ASSUMPTION] A3**: Unsigned addition only; no subtraction or signed overflow flags.
- **[ASSUMPTION] A4**: `rst_n` is asynchronous assert, synchronous deassert is acceptable for internal regs; outputs cleared while `rst_n` is low.
- **[ASSUMPTION] A5**: No backpressure or stall; pipeline always accepts new ops when `i_en` is pulsed.
- **[ASSUMPTION] A6**: `result` holds the last completed sum while `o_en` is high; when `o_en` is low, `result` value is don't-care for external use.

## 6. Diff vs original SPEC

| Original | Refined |
|----------|---------|
| Vague "several" pipeline stages | Fixed **4** stages, **16** bits each |
| No latency stated | **L = 4** cycles `i_en` → `o_en` |
| No `i_en` pulse vs level behavior | **R4–R5**, **A2** |
| No reset detail | **R1–R2**, **A4** |
| No unsigned / bit ordering | **R6–R7**, `result[64]` = carry |
| No operand stability rule | **R11** |
| No throughput | Steady-state **1 op/cycle** after fill |

## 7. Open for Agent2

1. **Stage typing**: Confirm each stage as `Sequential` (register segment sum + carry + operand upper slices) vs `Mixed` (combinational add within registered boundary).
2. **Enable pipeline**: Exact width and tap for `o_en` (shift register depth = 4 aligned with data path).
3. **Operand holding**: Whether full `adda`/`addb` are held in one input register for all segments or upper bits are forwarded stage-to-stage.
4. **Reset timing**: Async vs sync reset on individual pipeline registers — pick one style for synthesizability and document per stage.
5. **Bubble cycles**: Behavior of `o_en` when no launch for many cycles (should remain low).
