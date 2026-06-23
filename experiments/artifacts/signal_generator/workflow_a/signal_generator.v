// signal_generator
// 5-bit triangle wave generator: cycles 0→31→0 repeatedly.

module signal_generator (
    input       clk,    // clock
    input       rst_n,  // active-low async reset
    output [4:0] wave   // triangle wave output (0-31)
);

    reg       state;   // 0 = counting up, 1 = counting down
    reg [4:0] wave_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= 1'b0;
            wave_reg <= 5'd0;
        end else begin
            case (state)
                1'b0: begin
                    if (wave_reg == 5'd31) begin
                        state    <= 1'b1;
                        wave_reg <= wave_reg - 1'd1;
                    end else begin
                        wave_reg <= wave_reg + 1'd1;
                    end
                end
                1'b1: begin
                    if (wave_reg == 5'd0) begin
                        state    <= 1'b0;
                        wave_reg <= wave_reg + 1'd1;
                    end else begin
                        wave_reg <= wave_reg - 1'd1;
                    end
                end
            endcase
        end
    end

    assign wave = wave_reg;

endmodule
