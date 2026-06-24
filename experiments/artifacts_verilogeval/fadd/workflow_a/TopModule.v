// TopModule: full adder
// SPEC: spec/design.spec.txt
//
// Ports:
//   a    - input bit
//   b    - input bit
//   cin  - carry-in
//   sum  - a XOR b XOR cin
//   cout - (a & b) | (a & cin) | (b & cin)

module TopModule (
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);

    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);

endmodule
