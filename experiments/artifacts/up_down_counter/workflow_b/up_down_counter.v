//======================================================================
// up_down_counter
// 16-bit up/down counter.
// up_down=1 => increment, up_down=0 => decrement.
// Reset: synchronous, active-high reset, clears count to 0.
//======================================================================
module up_down_counter (
    input  wire       clk,
    input  wire       reset,
    input  wire       up_down,
    output reg [15:0] count
);

    //------------------------------------------------------------------
    // Stage 0: Up/Down counter register
    //------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset)
            count <= 16'b0;
        else if (up_down)
            count <= count + 1'b1;
        else
            count <= count - 1'b1;
    end

endmodule
