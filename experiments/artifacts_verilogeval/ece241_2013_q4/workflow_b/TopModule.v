// ece241_2013_q4 (VerilogEval #149)
// TopModule: Water reservoir level controller
// Positive-edge clock, synchronous active-high reset

module TopModule (
    input       clk,
    input       reset,
    input [2:0] s,
    output      fr2,
    output      fr1,
    output      fr0,
    output      dfr
);

    reg [1:0] level;
    reg dfr;

    wire [1:0] level_w;

    // Level decode from sensors
    assign level_w = (s == 3'b000) ? 2'd0 :
                     (s == 3'b001) ? 2'd1 :
                     (s == 3'b011) ? 2'd2 :
                     (s == 3'b111) ? 2'd3 : level;

    // Sequential
    always @(posedge clk) begin
        if (reset) begin
            level <= 2'd0;
            dfr   <= 1'd0;
        end else begin
            level <= level_w;
            if (level_w > level)
                dfr <= 1'd1;
            else if (level_w < level)
                dfr <= 1'd0;
        end
    end

    // Output logic
    assign fr2 = (level == 2'd0);
    assign fr1 = (level == 2'd0) || (level == 2'd1);
    assign fr0 = (level != 2'd3);

endmodule
