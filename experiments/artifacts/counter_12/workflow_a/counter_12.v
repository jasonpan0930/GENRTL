// counter_12
// 4-bit counter 0→11, enable-controlled, wrap-around.

module counter_12 (
    input        clk,          // clock
    input        rst_n,        // active-low async reset
    input        valid_count,  // count enable
    output [3:0] out           // count value
);

    reg [3:0] out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_reg <= 4'd0;
        else if (valid_count) begin
            if (out_reg == 4'd11)
                out_reg <= 4'd0;
            else
                out_reg <= out_reg + 1'd1;
        end
    end

    assign out = out_reg;

endmodule
