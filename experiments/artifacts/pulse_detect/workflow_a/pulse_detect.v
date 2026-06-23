// pulse_detect
// Detects a 0->1->0 pulse pattern on data_in over 3 cycles.
// data_out = 1 on the cycle data_in returns to 0 after a 1.

module pulse_detect (
    input  clk,      // clock
    input  rst_n,    // active-low async reset
    input  data_in,  // 1-bit input
    output data_out  // 1 when pulse (010) detected
);

    reg [1:0] state;
    reg       dout_reg;

    localparam S0 = 2'd0,  // idle, waiting for 0->1
               S1 = 2'd1,  // received a 1, waiting for 1->0
               S2 = 2'd2;  // pulse complete, assert data_out

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S0;
            dout_reg <= 1'b0;
        end else begin
            case (state)
                S0: begin
                    dout_reg <= 1'b0;
                    if (data_in)
                        state <= S1;
                end
                S1: begin
                    dout_reg <= 1'b0;
                    if (!data_in)
                        state <= S2;
                end
                S2: begin
                    dout_reg <= 1'b1;
                    if (data_in)
                        state <= S1;
                    else
                        state <= S0;
                end
                default: begin
                    state    <= S0;
                    dout_reg <= 1'b0;
                end
            endcase
        end
    end

    assign data_out = dout_reg;

endmodule
