# Timing & Structure Plan — gshare (VerilogEval #153)

## 1. Overview

Single module with a 128-entry PHT (reg array), a 7-bit global history register, XOR-based index calculation, and saturating counter update logic.

## 2. Hierarchy

Single module: `TopModule`. No submodules.

## 3. Stages

### Stage 0 — Global history register (Sequential)

**Clock**: posedge clk **or** posedge areset

**Reset**: asynchronous active-high; history = 7'd0

**Register**: `history` (7-bit)

**Update logic**:
- `history <= {train_history[5:0], train_taken}` if train_valid
- `history <= {history[5:0], predict_taken}` else if predict_valid

### Stage 0 — PHT array (Sequential)

**Register**: `pht[0:127]` (each 2-bit)

**Write** (at posedge clk):
- If train_valid: update saturating counter at index `train_pc ^ train_history`
  - train_taken=1 && ctr!=2'b11: ctr + 1
  - train_taken=0 && ctr!=2'b00: ctr - 1

### Stage 0 — Prediction read (Combinational)

**Inputs**: predict_valid, predict_pc, history, pht

**New declarations**:
- `wire [6:0] pred_idx;`
- `wire [1:0] pred_ctr;`

**Equations**:
- `pred_idx = predict_pc ^ history`
- `pred_ctr = pht[pred_idx]`
- `predict_taken = pred_ctr[1]` (MSB = taken when >= 2)
- `predict_history = history`

### Stage 0 — PHT write index (Combinational)

**Index**: `train_idx = train_pc ^ train_history`

## 4. Connectivity

None (single module).

## 5. FSM

None — purely a predictor with register array, no FSM needed.

## 6. Alignment checklist

- [x] Ports: clk, areset, predict_valid, predict_pc[6:0], predict_taken, predict_history[6:0], train_valid, train_taken, train_mispredicted, train_history[6:0], train_pc[6:0]
- [x] Port order matches original SPEC
- [x] areset asynchronous active-high
- [x] 7-bit global history register
- [x] XOR-based index: pc ^ history
- [x] 128 entries × 2-bit saturating counters
- [x] Prediction: combinational read from PHT
- [x] Training: sequential write to PHT
- [x] Training precedence over prediction for history
- [x] Saturating counter update rules

## 7. Open items

None.
