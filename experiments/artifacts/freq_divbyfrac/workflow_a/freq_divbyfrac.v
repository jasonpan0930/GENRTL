// freq_divbyfrac
// Fractional frequency divider (3.5x) using double-edge clocking.
// Counts through 7 cycles, generates two phase-shifted clocks, OR-ed together.

module freq_divbyfrac (
    input  clk,      // input clock
    input  rst_n,    // active-low async reset
    output clk_div   // fractionally divided clock (3.5x)
);

    localparam MUL2_DIV_CLK = 7;  // 2 * 3.5 = 7

    reg [2:0] cnt;        // 0..6 counter
    reg       clk_pos;    // phase on posedge
    reg       clk_neg;    // phase on negedge

    // Counter on posedge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 3'd0;
        else if (cnt == MUL2_DIV_CLK - 1)
            cnt <= 3'd0;
        else
            cnt <= cnt + 1'd1;
    end

    // clk_pos: high for 4 cycles, low for 3 cycles (posedge)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_pos <= 1'b0;
        else
            clk_pos <= (cnt < (MUL2_DIV_CLK / 2));  // high for cnt 0..3
    end

    // clk_neg: same toggle points but on negedge (half-cycle phase shift)
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_neg <= 1'b0;
        else
            clk_neg <= (cnt < (MUL2_DIV_CLK / 2));
    end

    // OR the two phase-shifted clocks to produce a smooth fractional output
    assign clk_div = clk_pos | clk_neg;

endmodule
