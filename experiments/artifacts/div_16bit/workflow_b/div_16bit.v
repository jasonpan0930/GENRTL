// div_16bit — 16-bit unsigned combinational divider
// Implements: result = A / B, odd = A % B

module div_16bit (
  input  [15:0] A,
  input  [7:0]  B,
  output [15:0] result,
  output [15:0] odd
);

  assign result = A / B;
  assign odd    = A % B;

endmodule
