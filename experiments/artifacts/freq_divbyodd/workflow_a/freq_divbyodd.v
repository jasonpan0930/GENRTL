// freq_divbyodd
// Odd-number clock divider. Uses dual-edge counters and OR-ed outputs
// for 50% duty cycle.

module freq_divbyodd #(
    parameter NUM_DIV = 5  // odd division factor; default 5
) (
    input  clk,      // input clock
    input  rst_n,    // active-low async reset
    output clk_div   // divided clock output
);

    reg [3:0] cnt1;       // posedge counter
    reg [3:0] cnt2;       // negedge counter
    reg       clk_div1;   // posedge clock divider
    reg       clk_div2;   // negedge clock divider

    // Rising-edge counter and divider
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt1      <= 4'd0;
            clk_div1  <= 1'b0;
        end else begin
            if (cnt1 == (NUM_DIV - 1))
                cnt1 <= 4'd0;
            else
                cnt1 <= cnt1 + 1'd1;

            if (cnt1 == (NUM_DIV - 1) / 2)
                clk_div1 <= ~clk_div1;
        end
    end

    // Falling-edge counter and divider
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt2      <= 4'd0;
            clk_div2  <= 1'b0;
        end else begin
            if (cnt2 == (NUM_DIV - 1))
                cnt2 <= 4'd0;
            else
                cnt2 <= cnt2 + 1'd1;

            if (cnt2 == (NUM_DIV - 1) / 2)
                clk_div2 <= ~clk_div2;
        end
    end

    // OR both edges for final divided clock
    assign clk_div = clk_div1 | clk_div2;

endmodule
