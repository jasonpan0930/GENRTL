// TopModule: 3-bit population count circuit
// SPEC: spec/design.spec.txt
//
// Ports:
//   in[2:0]  - 3-bit input vector
//   out[1:0] - 2-bit output, number of '1's in the input vector

module TopModule (
    input  [2:0] in,
    output [1:0] out
);

    assign out = in[0] + in[1] + in[2];

endmodule
