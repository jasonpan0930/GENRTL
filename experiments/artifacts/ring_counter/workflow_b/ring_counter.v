//======================================================================
// ring_counter
// 8-bit ring counter with one-hot rotation.
// Reset: synchronous, active-high reset, sets out to 8'b0000_0001.
//======================================================================
module ring_counter (
    input  wire       clk,
    input  wire       reset,
    output reg  [7:0] out
);

    //------------------------------------------------------------------
    // Stage 0: Ring shift register
    //------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset)
            out <= 8'b0000_0001;
        else
            out <= {out[6:0], out[7]};
    end

endmodule
