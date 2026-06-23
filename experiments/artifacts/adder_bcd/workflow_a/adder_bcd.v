// adder_bcd — 4-bit BCD adder for decimal arithmetic
// Implements: Sum = (A + B + Cin) with BCD correction
// SPEC: spec/design.spec.txt

module adder_bcd (
  input  [3:0] A,      // First BCD digit (0-9)
  input  [3:0] B,      // Second BCD digit (0-9)
  input        Cin,     // Carry-in
  output [3:0] Sum,    // BCD-corrected sum (0-9)
  output       Cout     // Carry-out
);

  wire [4:0] temp_sum;           // 5-bit binary sum
  wire       needs_correction;   // Correction needed when sum > 9

  assign temp_sum = A + B + Cin;

  // BCD correction is needed when:
  //   - bit 4 (carry) is set, OR
  //   - bits 3:0 exceed 9 (1001)
  assign needs_correction = temp_sum[4] | (temp_sum[3:0] > 4'd9);

  assign Cout = needs_correction;
  assign Sum  = needs_correction ? (temp_sum[3:0] + 4'd6) : temp_sum[3:0];

endmodule
