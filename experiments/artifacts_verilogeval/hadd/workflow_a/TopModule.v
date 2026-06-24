// TopModule: half adder
// SPEC: spec/design.spec.txt
//
// Ports:
//   a    - input bit
//   b    - input bit
//   sum  - a XOR b
//   cout - a AND b (carry-out)

module TopModule (
    input  a,
    input  b,
    output sum,
    output cout
);

    assign sum  = a ^ b;
    assign cout = a & b;

endmodule
