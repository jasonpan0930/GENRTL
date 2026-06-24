# Timing Plan — barrel_shifter

## 1. Overview

- **Design name**: barrel_shifter
- **Clock**: none (purely combinational)
- **Reset**: none
- **Dataflow**: in → Stage2 (mux by 4) → Stage1 (mux by 2) → Stage0 (mux by 1) → out

## 2. Hierarchy

| Module        | Type       | Notes                                  |
|---------------|------------|----------------------------------------|
| barrel_shifter| top        | External ports; instantiates 24× mux2X1 |
| mux2X1        | submodule  | 1-bit 2-to-1 multiplexer               |

## 3. Stages

### Stage 2 — Rotate by 4 (ctrl[2])

- **Type**: `Combinational`
- **Module**: barrel_shifter
- **Function**: Rotate left by 4 if ctrl[2]=1, else pass through

#### Inputs

| Signal | Width  | Source       | Registered? |
|--------|--------|--------------|-------------|
| in     | [7:0]  | port         | no          |
| ctrl[2]| 1      | port (ctrl)  | no          |

#### Outputs (new declarations)

| Signal         | Width  | Destination      | Next cycle? |
|----------------|--------|------------------|-------------|
| s2_out[0..7]   | 8×1    | Stage 1          | combinational (no reg) |

#### Combinational contents

For each bit i (0..7):
```
s2_out[i] = ctrl[2] ? in[(i+4)%8] : in[i];
```

**Exact mux2X1 wiring for Stage 2 (i = 0..7):**

| Mux instance | a (sel=0) | b (sel=1) | sel    | out      |
|-------------|-----------|-----------|--------|----------|
| u_s2_mux[i] | in[i]     | in[(i+4)%8] | ctrl[2] | s2_out[i] |

### Stage 1 — Rotate by 2 (ctrl[1])

- **Type**: `Combinational`
- **Module**: barrel_shifter
- **Function**: Rotate left by 2 if ctrl[1]=1, else pass through

#### Inputs

| Signal   | Width  | Source           | Registered? |
|----------|--------|------------------|-------------|
| s2_out[] | 8×1    | Stage 2          | no          |
| ctrl[1]  | 1      | port (ctrl)      | no          |

#### Outputs (new declarations)

| Signal         | Width  | Destination      | Next cycle? |
|----------------|--------|------------------|-------------|
| s1_out[0..7]   | 8×1    | Stage 0          | combinational (no reg) |

#### Combinational contents

For each bit i (0..7):
```
s1_out[i] = ctrl[1] ? s2_out[(i+2)%8] : s2_out[i];
```

**Exact mux2X1 wiring for Stage 1 (i = 0..7):**

| Mux instance | a (sel=0) | b (sel=1) | sel    | out        |
|-------------|-----------|-----------|--------|------------|
| u_s1_mux[i] | s2_out[i] | s2_out[(i+2)%8] | ctrl[1] | s1_out[i] |

### Stage 0 — Rotate by 1 (ctrl[0])

- **Type**: `Combinational`
- **Module**: barrel_shifter
- **Function**: Rotate left by 1 if ctrl[0]=1, else pass through

#### Inputs

| Signal   | Width  | Source           | Registered? |
|----------|--------|------------------|-------------|
| s1_out[] | 8×1    | Stage 1          | no          |
| ctrl[0]  | 1      | port (ctrl)      | no          |

#### Outputs (connect to top-level port)

| Signal     | Width  | Destination | Next cycle? |
|------------|--------|-------------|-------------|
| out[0..7]  | 8×1    | port        | combinational (no reg) |

#### Combinational contents

For each bit i (0..7):
```
out[i] = ctrl[0] ? s1_out[(i+1)%8] : s1_out[i];
```

**Exact mux2X1 wiring for Stage 0 (i = 0..7):**

| Mux instance | a (sel=0) | b (sel=1) | sel    | out       |
|-------------|-----------|-----------|--------|-----------|
| u_s0_mux[i] | s1_out[i] | s1_out[(i+1)%8] | ctrl[0] | out[i] |

### Submodule: mux2X1

- **Type**: `Combinational`
- **Module**: mux2X1
- **Function**: 1-bit 2-to-1 multiplexer

| Signal | Width | Direction | Logic                             |
|--------|-------|-----------|-----------------------------------|
| a      | 1     | input     | —                                 |
| b      | 1     | input     | —                                 |
| sel    | 1     | input     | —                                 |
| out    | 1     | output    | `out = sel ? b : a`               |

## 4. Connectivity (ASCII)

```
in[0..7] ──┐
ctrl[2] ───┤
            v
      [Stage 2: 8× mux2X1, shift by 4]
            │ s2_out[0..7]
            v
ctrl[1] ───┤
            v
      [Stage 1: 8× mux2X1, shift by 2]
            │ s1_out[0..7]
            v
ctrl[0] ───┤
            v
      [Stage 0: 8× mux2X1, shift by 1]
            │ out[0..7]
            v
         port out
```

## 5. FSM

No FSM. Purely combinational.

## 6. Alignment checklist

- [x] All ports assigned
- [x] No unintended combinational loops
- [x] Rotate (wrap-around), not logical shift
- [x] Stage order: ctrl[2]→ctrl[1]→ctrl[0]
- [x] Each mux instance has explicit a/b/sel connections per the equations
- [x] Port order matches original SPEC: in, ctrl, out

## 7. Open items / risks

- The design assumes rotate (wrap-around). If the testbench expects logical
  shift (zero-fill), all results will be wrong with probability related to
  how often bits fall off the MSB side. **[ASSUMPTION]**
- No clock domain concerns — purely combinational.
