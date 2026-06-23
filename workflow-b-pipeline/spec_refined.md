# Refined SPEC — adder_bcd (4-bit BCD Adder)

## §1 Overview

A 4-bit BCD (Binary-Coded Decimal) adder for decimal arithmetic. The module adds two BCD digits and a carry-in, produces a BCD-corrected sum digit and a carry-out. The circuit is **purely combinational** — no clock or sequential elements.

## §2 Interface

### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| A    | Input     | [3:0] | First BCD digit (0–9). Values A–F (10–15) are allowed as inputs; behavior is defined in §Corner cases. |
| B    | Input     | [3:0] | Second BCD digit (0–9). Values A–F (10–15) are allowed as inputs; behavior is defined in §Corner cases. |
| Cin  | Input     | [1:0] | Carry-in (1-bit, value 0 or 1). |
| Sum  | Output    | [3:0] | BCD-corrected sum digit (0–9), valid whenever inputs are stable. |
| Cout | Output    | [1:0] | Carry-out (1-bit), asserted when the decimal sum ≥ 10. |

### Port order (match testbench expectation)

```
adder_bcd(A, B, Cin, Sum, Cout);
```

No clock, no reset — this is a combinational module.

## §3 Operation

### 3.1 Binary addition

```
temp_sum = A + B + Cin;    // 5-bit result (0…19)
```

### 3.2 BCD correction

- If `temp_sum > 9` (i.e. `temp_sum >= 4'd10`):
  - `Sum = (temp_sum + 4'd6) & 4'hF` (add 6, keep lower 4 bits)
  - `Cout = 1'b1`
- Else:
  - `Sum = temp_sum[3:0]`
  - `Cout = 1'b0`

### 3.3 Correction logic (testable)

| Condition                     | Sum output | Cout |
|-------------------------------|------------|------|
| `A + B + Cin <= 9`           | `A+B+Cin`  | 0    |
| `A + B + Cin >= 10`          | `A+B+Cin+6` (lower 4 bits) | 1    |

### 3.4 Boolean equations (informative)

```
temp      = A + B + Cin;              // 5-bit
Cout      = (temp > 4'd9);
correction = (Cout) ? 4'd6 : 4'd0;
Sum       = (temp + correction) [3:0];
```

## §4 Timing

The module is **combinational** — all outputs settle within the propagation delay of the logic. There is no clock, no reset, no sequential element.

### 4.1 Latency

- Pure combinational: outputs reflect inputs after logic gate delay (~1–2 ns in typical technology).
- No pipelining; no register stages.

### 4.2 No handshake interfaces

The design has no valid/ready pairs. Outputs (Sum, Cout) are always valid when inputs are stable.

## §5 Reset

**Not applicable.** The module contains no sequential elements (flip-flops, registers, counters, FSMs). No reset signal is required or defined.

[ASSUMPTION] The original SPEC does not mention a clock or reset. This module is purely combinational, therefore no reset is needed.

## §6 Corner cases

### 6.1 Invalid BCD inputs (A or B in range 10–15)

The SPEC states A and B are "BCD inputs representing a digit 0–9", but the input ports are 4-bit wide (0–15). When A and/or B carry values 10–15:

- **Binary addition is still performed** — the module does not clamp or detect invalid BCD digits.
- Correction fires if `A + B + Cin ≥ 10`, which will be true for most invalid combinations.
- **Example:** A = 4'd15 (1111), B = 4'd0, Cin = 0 → temp_sum = 15 → correction fires → Sum = (15 + 6) & 0xF = 5, Cout = 1.
- The testbench may supply invalid BCD values; the module must produce consistent, deterministic outputs for all 256 × 2 = 512 input combinations.

### 6.2 Maximum input sum

A = 15, B = 15, Cin = 1 → temp_sum = 31 → Sum = (31 + 6) & 0xF = 1 (since 37 & 0xF = 5... wait, 37 mod 16 = 5), actually 37 & 0xF = 5, Cout = 1.

Actually let me recalculate: 15 + 15 + 1 = 31. 31 + 6 = 37. 37 & 0xF = 5 (since 37 = 0x25, lower nibble = 5). Cout = 1.

### 6.3 Carry-in when Cin > 1

Cin is defined as 1-bit, so its value is always 0 or 1. No corner case.

### 6.4 Overflow

The Cout signal serves as the overflow indicator for BCD addition. When chaining multiple BCD adders, Cout of stage N feeds Cin of stage N+1. The module handles a full chain correctly since it is combinational.

## §7 Assumptions and resolutions

| # | Assumption | Resolution |
|---|------------|------------|
| 1 | Module is purely combinational (no clock, no reset). | Accepted. Original SPEC does not mention sequential elements. |
| 2 | Input ports A and B may receive values beyond 0–9. | Accepted. The module performs add/correct on any 4-bit values; output may not be a valid BCD digit, but behavior is deterministic. |
| 3 | Port order is `A, B, Cin, Sum, Cout` matching the original SPEC. | Accepted. Must not be reordered. |

## §8 Diff vs original SPEC

| Aspect | Original SPEC | Refined SPEC |
|--------|---------------|--------------|
| Ports   | Listed A, B, Cin, Sum, Cout | Same ports, widths confirmed; port order explicitly stated. |
| Clock/Reset | Not mentioned | Explicitly stated: none (combinational). Added [ASSUMPTION]. |
| BCD correction | "If sum exceeds 9, add 6" | Exact equation: `temp_sum + 6`, lower 4 bits. Also: Cout = (temp_sum > 9). |
| Invalid inputs | Not discussed | §6 corner cases: deterministic behavior for A/B values 10–15. |
| Testable conditions | None | §3.3 table: exact Sum and Cout for each condition. |
