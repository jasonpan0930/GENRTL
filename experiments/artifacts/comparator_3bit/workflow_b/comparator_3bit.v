// comparator_3bit — 3-bit binary comparator
// Stage 0 (Combinational): comparison logic
// All outputs are mutually exclusive combinational functions of A and B.

module comparator_3bit (
  input  [2:0] A,
  input  [2:0] B,
  output       A_greater,
  output       A_equal,
  output       A_less
);

  // Internal wires
  wire eq_bit2, eq_bit1, eq_bit0;
  wire gt_bit2, gt_bit1, gt_bit0;

  // Bit-wise equality
  assign eq_bit2 = A[2] ~^ B[2];
  assign eq_bit1 = A[1] ~^ B[1];
  assign eq_bit0 = A[0] ~^ B[0];

  // Bit-wise greater
  assign gt_bit2 =  A[2]  & ~B[2];
  assign gt_bit1 =  A[1]  & ~B[1];
  assign gt_bit0 =  A[0]  & ~B[0];

  // A_greater: hierarchical comparison (MSB first)
  assign A_greater = gt_bit2 |
                     (eq_bit2 & gt_bit1) |
                     (eq_bit2 & eq_bit1 & gt_bit0);

  // A_equal: all bits equal
  assign A_equal = eq_bit2 & eq_bit1 & eq_bit0;

  // A_less: complement of greater and equal (mutually exclusive)
  assign A_less = ~A_greater & ~A_equal;

endmodule
