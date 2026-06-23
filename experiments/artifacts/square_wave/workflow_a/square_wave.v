// square_wave
// Square wave generator with variable frequency.
// Toggles wave_out every freq input clock cycles.

module square_wave (
    input        clk,     // clock
    input  [7:0] freq,    // frequency control (cycles between toggles)
    output       wave_out // square wave output
);

    reg [7:0] count;
    reg       wave_out_reg;

    always @(posedge clk) begin
        if (count == (freq - 1'b1)) begin
            count        <= 8'd0;
            wave_out_reg <= ~wave_out_reg;
        end else begin
            count <= count + 1'd1;
        end
    end

    assign wave_out = wave_out_reg;

endmodule
