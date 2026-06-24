// TopModule: 2-bit equality comparator
// SPEC: spec/design.spec.txt
//
// Ports:
//   A[1:0] - 2-bit input
//   B[1:0] - 2-bit input
//   z      - 1 if A == B, else 0

module TopModule (
    input  [1:0] A,
    input  [1:0] B,
    output       z
);

    assign z = (A == B);

endmodule
