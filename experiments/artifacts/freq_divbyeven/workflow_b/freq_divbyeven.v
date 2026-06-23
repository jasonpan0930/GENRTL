// freq_divbyeven — Even frequency divider
// Divides input clock by even NUM_DIV using a 4-bit counter

module freq_divbyeven (
    input  clk,
    input  rst_n,
    output reg clk_div
);

    parameter NUM_DIV = 6;

    reg [3:0] cnt;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            cnt     <= 4'd0;
            clk_div <= 1'b0;
        end else if (cnt < NUM_DIV / 2 - 1) begin
            cnt     <= cnt + 1'b1;
            clk_div <= clk_div;
        end else begin
            cnt     <= 4'd0;
            clk_div <= ~clk_div;
        end

endmodule
