// Dual-edge triggered flip-flop
// Captures d on both posedge and negedge of clk
// Uses two single-edge FFs plus clock-level mux

module TopModule (
    input  wire clk,
    input  wire d,
    output wire q
);

    // Internal storage: capture d on opposite clock edges
    reg pos_ff;
    reg neg_ff;

    // Stage 0a: Capture d on rising edge
    always @(posedge clk) begin
        pos_ff <= d;
    end

    // Stage 0b: Capture d on falling edge
    always @(negedge clk) begin
        neg_ff <= d;
    end

    // Stage 0c: Select appropriate captured value based on clock phase
    assign q = clk ? pos_ff : neg_ff;

endmodule
