// TopModule: 256-to-1 multiplexer (4-bit wide)
// SPEC: spec/design.spec.txt
//
// Ports:
//   in[1023:0] - 1024-bit input (256 × 4-bit groups)
//   sel[7:0]   - 8-bit select
//   out[3:0]   - selected 4-bit group

module TopModule (
    input  [1023:0] in,
    input  [   7:0] sel,
    output [   3:0] out
);

    assign out = in[sel*4 +: 4];

endmodule
