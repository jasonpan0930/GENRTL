// ============================================================
// adder_16bit — 16-bit full adder (combinational)
//
// SPEC ref: spec/design.spec.txt
//   - 16-bit full adder in combinational logic
//   - Uses 8-bit adder submodule (adder_8bit) instantiated twice
// ============================================================

module adder_8bit (
  input  [7:0] a,
  input  [7:0] b,
  input        Cin,
  output [7:0] y,
  output       Co
);
  assign {Co, y} = a + b + Cin;
endmodule


module adder_16bit (
  input  [15:0] a,      // [SPEC] 16-bit input operand A
  input  [15:0] b,      // [SPEC] 16-bit input operand B
  input         Cin,    // [SPEC] Carry-in input
  output [15:0] y,      // [SPEC] 16-bit sum output
  output        Co      // [SPEC] Carry-out output
);
  wire carry_mid;

  adder_8bit u_lo (
    .a   (a[7:0]),
    .b   (b[7:0]),
    .Cin (Cin),
    .y   (y[7:0]),
    .Co  (carry_mid)
  );

  adder_8bit u_hi (
    .a   (a[15:8]),
    .b   (b[15:8]),
    .Cin (carry_mid),
    .y   (y[15:8]),
    .Co  (Co)
  );
endmodule
