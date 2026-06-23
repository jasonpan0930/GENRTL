// right_shifter
// 8-bit right shifter: on each rising clock edge, shift right by 1
// and insert input d into the MSB.
// [ASSUMPTION] rst_n added per Workflow A convention (SPEC has no reset).

module right_shifter (
    input        clk,    // clock
    input        rst_n,  // active-low asynchronous reset (synchronous deassert)
    input        d,      // input bit to shift into MSB
    output [7:0] q       // shifted output
);

    reg [7:0] q_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q_reg <= 8'd0;
        else begin
            q_reg <= (q_reg >> 1);
            q_reg[7] <= d;
        end
    end

    assign q = q_reg;

endmodule
