// up_down_counter
// 16-bit up/down counter, synchronous reset.

module up_down_counter (
    input          clk,      // clock
    input          reset,    // synchronous active-high reset
    input          up_down,  // 1=count up, 0=count down
    output [15:0]  count     // current count value
);

    reg [15:0] count_reg;

    always @(posedge clk) begin
        if (reset)
            count_reg <= 16'd0;
        else if (up_down)
            count_reg <= count_reg + 1'd1;
        else
            count_reg <= count_reg - 1'd1;
    end

    assign count = count_reg;

endmodule
