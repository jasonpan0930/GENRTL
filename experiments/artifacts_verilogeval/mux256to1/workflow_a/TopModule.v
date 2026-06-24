// TopModule: 256-to-1 multiplexer (1-bit wide)
// SPEC: spec/design.spec.txt
//
// Ports:
//   in[255:0] - 256-bit input vector
//   sel[7:0]  - 8-bit select
//   out       - selected bit

module TopModule (
    input  [255:0] in,
    input  [  7:0] sel,
    output         out
);

    assign out = in[sel];

endmodule
