// TopModule — Rule 110 cellular automaton (VerilogEval #124)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input            clk,
    input            load,
    input  [511:0]   data,
    output reg [511:0] q
);

    // Stage 0 — Next-state combinational logic
    reg [511:0] q_next;
    integer i;

    always @(*) begin
        for (i = 0; i < 512; i = i + 1) begin
            if (i == 0) begin
                // Left neighbor (q[-1]) is 0
                q_next[i] = (q[i] & ~1'b0)
                          | (~q[i+1] & q[i])
                          | (~q[i+1] & 1'b0);
            end else if (i == 511) begin
                // Right neighbor (q[512]) is 0
                q_next[i] = (q[i] & ~q[i-1])
                          | (~1'b0 & q[i])
                          | (~1'b0 & q[i-1]);
            end else begin
                q_next[i] = (q[i] & ~q[i-1])
                          | (~q[i+1] & q[i])
                          | (~q[i+1] & q[i-1]);
            end
        end
    end

    // Stage 0 — State register (Sequential)
    always @(posedge clk) begin
        if (load)
            q <= data;
        else
            q <= q_next;
    end

endmodule
