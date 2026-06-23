//======================================================================
// counter_12
// 4-bit counter, counts 0..11, enable via valid_count, wraps at 11.
// Reset: synchronous, active-low rst_n.
//======================================================================
module counter_12 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_count,
    output reg  [3:0] out
);

    //------------------------------------------------------------------
    // Stage 0: Counter register
    //------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n)
            out <= 4'b0000;
        else if (valid_count) begin
            if (out == 4'd11)
                out <= 4'b0000;
            else
                out <= out + 1'b1;
        end
    end

endmodule
