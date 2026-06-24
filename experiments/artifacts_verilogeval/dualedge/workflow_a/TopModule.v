// TopModule: dual-edge triggered flip-flop
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk - clock
//   d   - data input
//   q   - output (changes on both clock edges)

module TopModule (
    input clk,
    input d,
    output q
);

    reg q_pos, q_neg;

    always @(posedge clk) q_pos <= d;
    always @(negedge clk) q_neg <= d;

    assign q = clk ? q_pos : q_neg;

endmodule
