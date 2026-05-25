# Timing & Structure Plan — adder_pipe_64bit

## 1. Overview

- **Design name**: `adder_pipe_64bit`
- **Clock**: Rising edge of `clk`; single clock domain
- **Reset**: `rst_n` active low; asynchronous assert clears all pipeline registers and `o_en`; synchronous release on deassert
- **Dataflow one-liner**: `(adda, addb, i_en)` → input capture (S) → seg0 add (M) → seg1 add (M) → seg2 add (M) → seg3 add + pack (M) → `(result, o_en)`

## 2. Hierarchy

| Module | Type | Notes |
|--------|------|-------|
| `adder_pipe_64bit` | top | Single-file top; no submodules required |

## 3. Stages

### Stage 0 — Input capture & segment 0

- **Type**: `Mixed`
- **Module**: `adder_pipe_64bit`
- **Function**: On `i_en`, register full `adda`/`addb`; compute 17-bit ripple sum of `[15:0]`; register partial sum, carry, and enable bit into stage 1.

#### Inputs

| Signal | Width | Source (stage/port) | Registered? |
|--------|-------|---------------------|-------------|
| `adda` | 64 | port | No (sampled when `i_en`) |
| `addb` | 64 | port | No |
| `i_en` | 1 | port | No |
| `clk`, `rst_n` | 1 | port | — |

#### Outputs

| Signal | Width | Destination | Next cycle? |
|--------|-------|-------------|-------------|
| `op_adda` | 64 | Stage 1 | Yes |
| `op_addb` | 64 | Stage 1 | Yes |
| `sum0` | 16 | Stage 1 | Yes |
| `c0` | 1 | Stage 1 | Yes |
| `en_s0` | 1 | enable chain | Yes |

#### Timing

- **Clock**: posedge `clk`
- **Reset**: `rst_n` low → clear `op_adda`, `op_addb`, `sum0`, `c0`, `en_s0`
- **Latency (cycles)**: 1 from launch edge

#### Combinational / sequential contents

- **Comb**: `tmp0 = adda[15:0] + addb[15:0]` (17-bit)
- **Seq**: if `i_en`, latch `adda`, `addb`; latch `sum0 = tmp0[15:0]`, `c0 = tmp0[16]`, `en_s0 <= 1`; else hold unless reset

---

### Stage 1 — Segment 1 [31:16]

- **Type**: `Mixed`
- **Module**: `adder_pipe_64bit`
- **Function**: Add `op_adda[31:16] + op_addb[31:16] + c0`; register `sum1`, `c1`, propagate enable.

#### Inputs

| Signal | Width | Source | Registered? |
|--------|-------|--------|-------------|
| `op_adda[31:16]` | 16 | Stage 0 | Yes (from full op) |
| `op_addb[31:16]` | 16 | Stage 0 | Yes |
| `c0` | 1 | Stage 0 | Yes |
| `en_s0` | 1 | Stage 0 | Yes |

#### Outputs

| Signal | Width | Destination | Next cycle? |
|--------|-------|-------------|-------------|
| `sum1` | 16 | Stage 2 | Yes |
| `c1` | 1 | Stage 2 | Yes |
| `op_adda` | 64 | Stage 2 | Yes (pass-through) |
| `op_addb` | 64 | Stage 2 | Yes |
| `en_s1` | 1 | enable chain | Yes |

#### Timing

- **Clock**: posedge `clk`
- **Reset**: clear segment regs and `en_s1`
- **Latency (cycles)**: cumulative 2 from launch

#### Combinational / sequential contents

- **Comb**: `tmp1 = op_adda[31:16] + op_addb[31:16] + c0`
- **Seq**: register `sum1`, `c1`, pass `op_adda`/`op_addb`, `en_s1 <= en_s0`

---

### Stage 2 — Segment 2 [47:32]

- **Type**: `Mixed`
- **Module**: `adder_pipe_64bit`
- **Function**: Add bits [47:32] with `c1`; register `sum2`, `c2`, enable.

#### Inputs

| Signal | Width | Source | Registered? |
|--------|-------|--------|-------------|
| `op_adda[47:32]` | 16 | Stage 1 | Yes |
| `op_addb[47:32]` | 16 | Stage 1 | Yes |
| `c1` | 1 | Stage 1 | Yes |
| `en_s1` | 1 | Stage 1 | Yes |

#### Outputs

| Signal | Width | Destination | Next cycle? |
|--------|-------|-------------|-------------|
| `sum2` | 16 | Stage 3 | Yes |
| `c2` | 1 | Stage 3 | Yes |
| `op_adda`, `op_addb` | 64 | Stage 3 | Yes |
| `en_s2` | 1 | enable chain | Yes |

#### Timing

- **Clock**: posedge `clk`
- **Reset**: clear segment regs and `en_s2`
- **Latency (cycles)**: cumulative 3 from launch

#### Combinational / sequential contents

- **Comb**: `tmp2 = op_adda[47:32] + op_addb[47:32] + c1`
- **Seq**: register `sum2`, `c2`, pass operands, `en_s2 <= en_s1`

---

### Stage 3 — Segment 3 [63:48] & output pack

- **Type**: `Mixed`
- **Module**: `adder_pipe_64bit`
- **Function**: Add bits [63:48] with `c2`; assemble `result = {c3, sum3, sum2, sum1, sum0}`; drive `o_en` from delayed enable.

#### Inputs

| Signal | Width | Source | Registered? |
|--------|-------|--------|-------------|
| `op_adda[63:48]` | 16 | Stage 2 | Yes |
| `op_addb[63:48]` | 16 | Stage 2 | Yes |
| `c2` | 1 | Stage 2 | Yes |
| `sum0`, `sum1`, `sum2` | 16 each | Stage 2 pipeline | Yes |
| `en_s2` | 1 | Stage 2 | Yes |

#### Outputs

| Signal | Width | Destination | Next cycle? |
|--------|-------|-------------|-------------|
| `result` | 65 | port | Yes (reg output) |
| `o_en` | 1 | port | Yes (reg output) |

#### Timing

- **Clock**: posedge `clk`
- **Reset**: `result <= 0`, `o_en <= 0`
- **Latency (cycles)**: **4** from launch (`i_en`) to valid `result`/`o_en`

#### Combinational / sequential contents

- **Comb**: `tmp3 = op_adda[63:48] + op_addb[63:48] + c2`; pack `result_next = {tmp3[16], tmp3[15:0], sum2, sum1, sum0}`
- **Seq**: `result <= result_next`, `o_en <= en_s2` on posedge

#### Handshake / backpressure

- None; `o_en` tracks enable pipeline depth = 4.

## 4. Connectivity (ASCII)

```
adda,addb,i_en ──► [Stage0: latch op + sum0,c0] ──► [Stage1: sum1,c1] ──► [Stage2: sum2,c2] ──► [Stage3: sum3 + pack] ──► result,o_en
                      en_s0 ──────────────────────────► en_s1 ─────────────► en_s2 ─────────────► o_en
```

## 5. FSM

No explicit FSM. Control is the **enable shift chain** `en_s0 → en_s1 → en_s2 → o_en` aligned with the datapath.

| State variable | Meaning |
|----------------|---------|
| `en_s0` | Operation active after stage 0 |
| `en_s1` | Active in stage 1 |
| `en_s2` | Active in stage 2 |
| `o_en` | Result valid at stage 3 output |

## 6. Alignment checklist

- [x] All ports assigned to top or a stage
- [x] No unintended combinational loops (carry only forward in time)
- [x] Throughput/latency match spec: L=4, 1 op/cycle steady state per **A2/A5**

## 7. Open items / risks

- **[ASSUMPTION]**: Full `op_adda`/`op_addb` pass through all stages so upper slices remain available without re-fetching ports.
- **[ASSUMPTION]**: `en_s*` shifts every cycle while pipeline valid; when `en_s0` never set, chain stays low.
- Risk: If `i_en` held high multiple cycles, multiple `en` bits propagate — matches spec **R5**.
