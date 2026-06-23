// freq_divbyeven
// Even-number clock divider. Parameter NUM_DIV specifies the division factor.
// clk_div toggles every NUM_DIV/2 input clock cycles.

module freq_divbyeven #(
    parameter NUM_DIV = 4  // must be even; default 4
) (
    input  clk,      // input clock
    input  rst_n,    // active-low async reset
    output clk_div   // divided clock output
);

    reg [3:0] cnt;          // 4-bit counter (§Counter)
    reg       clk_div_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt        <= 4'd0;
            clk_div_reg <= 1'b0;
        end else if (cnt < (NUM_DIV / 2 - 1)) begin
            cnt <= cnt + 1'd1;
        end else begin
            cnt        <= 4'd0;
            clk_div_reg <= ~clk_div_reg;
        end
    end

    assign clk_div = clk_div_reg;

endmodule
