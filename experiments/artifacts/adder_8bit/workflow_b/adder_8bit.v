// adder_8bit — 8-bit ripple-carry adder using full-adder cells
// SPEC ref: spec_refined.md §3
// Timing: timing_plan.md Stage 0

module adder_8bit (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);

    // Internal carry chain (carry[0] = cin; carry[8] = cout)
    wire [8:1] carry;

    // Full-adder for bit 0
    assign sum[0]   = a[0] ^ b[0] ^ cin;
    assign carry[1] = (a[0] & b[0]) | (a[0] & cin) | (b[0] & cin);

    // Full-adder for bit 1
    assign sum[1]   = a[1] ^ b[1] ^ carry[1];
    assign carry[2] = (a[1] & b[1]) | (a[1] & carry[1]) | (b[1] & carry[1]);

    // Full-adder for bit 2
    assign sum[2]   = a[2] ^ b[2] ^ carry[2];
    assign carry[3] = (a[2] & b[2]) | (a[2] & carry[2]) | (b[2] & carry[2]);

    // Full-adder for bit 3
    assign sum[3]   = a[3] ^ b[3] ^ carry[3];
    assign carry[4] = (a[3] & b[3]) | (a[3] & carry[3]) | (b[3] & carry[3]);

    // Full-adder for bit 4
    assign sum[4]   = a[4] ^ b[4] ^ carry[4];
    assign carry[5] = (a[4] & b[4]) | (a[4] & carry[4]) | (b[4] & carry[4]);

    // Full-adder for bit 5
    assign sum[5]   = a[5] ^ b[5] ^ carry[5];
    assign carry[6] = (a[5] & b[5]) | (a[5] & carry[5]) | (b[5] & carry[5]);

    // Full-adder for bit 6
    assign sum[6]   = a[6] ^ b[6] ^ carry[6];
    assign carry[7] = (a[6] & b[6]) | (a[6] & carry[6]) | (b[6] & carry[6]);

    // Full-adder for bit 7
    assign sum[7]   = a[7] ^ b[7] ^ carry[7];
    assign cout     = (a[7] & b[7]) | (a[7] & carry[7]) | (b[7] & carry[7]);

endmodule
