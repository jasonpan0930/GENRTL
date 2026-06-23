// comparator_3bit — 3-bit binary comparator
// SPEC: spec/design.spec.txt
//
// Compares two 3-bit binary numbers A and B.
// Outputs are mutually exclusive: exactly one is high at any time.
//
// Ports:
//   A[2:0]       — First 3-bit input operand
//   B[2:0]       — Second 3-bit input operand
//   A_greater    — 1 when A > B
//   A_equal      — 1 when A == B
//   A_less       — 1 when A < B

module comparator_3bit (
    input  [2:0] A,
    input  [2:0] B,
    output       A_greater,
    output       A_equal,
    output       A_less
);

    assign A_greater = (A > B);
    assign A_equal   = (A == B);
    assign A_less    = (A < B);

endmodule
