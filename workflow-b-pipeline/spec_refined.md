# Refined Specification — gshare (VerilogEval #153)

## 1. Overview

A gshare branch predictor with 7-bit PC, 7-bit global history register, XOR-based index hashing, and a 128-entry pattern history table (PHT) of 2-bit saturating counters. Asynchronous active-high reset.

## 2. Interface (Ports)

| Port               | Width | Direction | Description |
|--------------------|-------|-----------|-------------|
| clk                | 1     | input     | Clock, positive edge |
| areset             | 1     | input     | Asynchronous active-high reset |
| predict_valid      | 1     | input     | Prediction request valid |
| predict_pc         | 7     | input     | PC of branch to predict |
| predict_taken      | 1     | output    | Predicted direction |
| predict_history    | 7     | output    | Global history used for prediction |
| train_valid        | 1     | input     | Training request valid |
| train_taken        | 1     | input     | Actual branch outcome |
| train_mispredicted | 1     | input     | Branch was mispredicted |
| train_history      | 7     | input     | Global history at branch time |
| train_pc           | 7     | input     | PC of branch being trained |

**Port order must match**: clk, areset, predict_valid, predict_pc[6:0], predict_taken, predict_history[6:0], train_valid, train_taken, train_mispredicted, train_history[6:0], train_pc[6:0].

### Reset

- Port name: `areset`
- Polarity: active-high
- Behavior: **asynchronous** (posedge clk or posedge areset). Resets history register to 0.

## 3. Functional requirements (testable items)

### Global history register

7-bit register. Updated at each positive clock edge:
- If `train_valid`: history <= {train_history[5:0], train_taken} (training provides ground truth)
- Else if `predict_valid`: history <= {history[5:0], predict_taken} (speculative update)

Reset (async): history = 7'd0.

### PHT (Pattern History Table)

128 entries, each a 2-bit saturating counter:
- 2'b00 → strongly not taken
- 2'b01 → weakly not taken
- 2'b10 → weakly taken
- 2'b11 → strongly taken

Index computation: `index = pc[6:0] ^ history[6:0]`

#### Read (prediction)

When predict_valid=1: index = predict_pc ^ history (current global history).

predict_taken = pht[index][1] (MSB). Taken if counter >= 2.

predict_history = current history register value (before update).

#### Write (training)

When train_valid=1: index = train_pc ^ train_history.

Update saturating counter:
- train_taken=1: if counter != 2'b11, counter <= counter + 1
- train_taken=0: if counter != 2'b00, counter <= counter - 1

#### Read during write

If training and prediction access the same PHT entry in the same cycle, the prediction sees the PRE-training state (because training updates at the clock edge while the prediction reads the current combinational value). This matches the spec timing diagram.

### History update precedence

- `train_valid` takes precedence over `predict_valid` for updating the global history register (training is the ground truth).
- If train_mispredicted=1, the history is recovered to `{train_history[5:0], train_taken}`.

## 4. Timing and performance

### Clock
- All sequential logic on posedge clk.

### Reset
- areset is asynchronous active-high. When high: history = 0.

### Prediction timing
- predict_taken and predict_history are combinational outputs (valid in same cycle as predict_valid).

### Training timing
- PHT updates at the clock edge where train_valid=1.

## 5. Assumptions and resolutions

- [ASSUMPTION] The global history register is updated by shifting in the branch outcome at the LSB: `{old_h[5:0], outcome}`.
- [ASSUMPTION] The initial history after reset is 7'd0.
- [ASSUMPTION] PHT is initialized to 2'b10 (weakly taken) or does not need initialization (write-before-read guaranteed by the testbench); we use 2'b00 as default.

## 6. Diff vs original SPEC

- Explicitly defined PHT update rules.
- Specified global history shift direction (LSB insertion).
- Clarified the read-during-write behavior for simultaneous prediction/training.
- Specified training-over-prediction precedence for history updates.

## 7. Open for Agent2

- Confirm PHT initialization (all zeros vs weakly taken).
