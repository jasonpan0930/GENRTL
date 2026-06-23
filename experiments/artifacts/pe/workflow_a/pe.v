// pe
// 32-bit Multiply-Accumulator (MAC) processing element.
// c <= c + (a * b), active-high reset.

module pe (
    input        clk,  // clock
    input        rst,  // active-high async reset
    input  [31:0] a,   // operand A
    input  [31:0] b,   // operand B
    output [31:0] c    // accumulated result
);

    reg [31:0] c_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            c_reg <= 32'd0;
        else
            c_reg <= c_reg + (a * b);
    end

    assign c = c_reg;

endmodule
