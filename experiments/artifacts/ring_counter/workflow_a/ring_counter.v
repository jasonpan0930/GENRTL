// ring_counter
// 8-bit ring counter: single 1-bit rotates through all positions.

module ring_counter (
    input       clk,    // clock
    input       reset,  // active-high async reset
    output [7:0] out    // ring counter state
);

    reg [7:0] out_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            out_reg <= 8'b0000_0001;
        else
            out_reg <= {out_reg[6:0], out_reg[7]};
    end

    assign out = out_reg;

endmodule
