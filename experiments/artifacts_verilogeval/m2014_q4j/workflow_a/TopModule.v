// TopModule: 4-bit ripple-carry adder built from full adders
// SPEC: spec/design.spec.txt
//
// Ports:
//   x[3:0]   - 4-bit input
//   y[3:0]   - 4-bit input
//   sum[4:0] - 5-bit output (includes overflow)

module TopModule (
    input  [3:0] x,
    input  [3:0] y,
    output [4:0] sum
);

    wire [3:0] c;   // internal carries (c[i] is carry out of bit i)

    // Full adder bit 0: sum = a ^ b, cout = a & b
    assign sum[0] = x[0] ^ y[0];
    assign c[0]   = x[0] & y[0];

    // Full adder bit 1: sum = a ^ b ^ cin, cout = (a&b) | (a&cin) | (b&cin)
    assign sum[1] = x[1] ^ y[1] ^ c[0];
    assign c[1]   = (x[1] & y[1]) | (x[1] & c[0]) | (y[1] & c[0]);

    // Full adder bit 2
    assign sum[2] = x[2] ^ y[2] ^ c[1];
    assign c[2]   = (x[2] & y[2]) | (x[2] & c[1]) | (y[2] & c[1]);

    // Full adder bit 3
    assign sum[3] = x[3] ^ y[3] ^ c[2];
    assign c[3]   = (x[3] & y[3]) | (x[3] & c[2]) | (y[3] & c[2]);

    // Final carry to MSB
    assign sum[4] = c[3];

endmodule
