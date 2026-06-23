// freq_div
// Frequency divider: 100MHz -> 50MHz (/2), 10MHz (/10), 1MHz (/100).
// SPEC ports: CLK_in (clock), RST (active-high async reset).

module freq_div (
    input  CLK_in,  // input clock (100MHz)
    input  RST,     // active-high async reset
    output CLK_50,  // CLK_in / 2  (50MHz)
    output CLK_10,  // CLK_in / 10 (10MHz)
    output CLK_1    // CLK_in / 100 (1MHz)
);

    reg clk_50_reg;
    reg clk_10_reg;
    reg clk_1_reg;

    reg [2:0] cnt_10;   // 0..4 for /10
    reg [5:0] cnt_100;  // 0..49 for /100

    // CLK_50 generation: toggle on every posedge
    always @(posedge CLK_in or posedge RST) begin
        if (RST)
            clk_50_reg <= 1'b0;
        else
            clk_50_reg <= ~clk_50_reg;
    end

    assign CLK_50 = clk_50_reg;

    // CLK_10 generation: /10 counter
    always @(posedge CLK_in or posedge RST) begin
        if (RST) begin
            clk_10_reg <= 1'b0;
            cnt_10     <= 3'd0;
        end else if (cnt_10 == 3'd4) begin
            clk_10_reg <= ~clk_10_reg;
            cnt_10     <= 3'd0;
        end else begin
            cnt_10 <= cnt_10 + 1'd1;
        end
    end

    assign CLK_10 = clk_10_reg;

    // CLK_1 generation: /100 counter
    always @(posedge CLK_in or posedge RST) begin
        if (RST) begin
            clk_1_reg  <= 1'b0;
            cnt_100    <= 6'd0;
        end else if (cnt_100 == 6'd49) begin
            clk_1_reg  <= ~clk_1_reg;
            cnt_100    <= 6'd0;
        end else begin
            cnt_100 <= cnt_100 + 1'd1;
        end
    end

    assign CLK_1 = clk_1_reg;

endmodule
