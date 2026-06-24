// TopModule — 2013_q2afsm (VerilogEval #148)
// Ref: spec_refined.md §3, timing_plan.md
// Uses separate always blocks for state table and flip-flops per SPEC.

module TopModule (
    input        clk,
    input        resetn,
    input  [2:0] r,
    output [2:0] g
);

    // FSM state encoding
    localparam A = 2'd0,
               B = 2'd1,
               C = 2'd2,
               D = 2'd3;

    // Stage 0 — State register
    reg [1:0] state;

    // Stage 0 — State table (combinational next-state logic)
    reg [1:0] nstate;

    always @(*) begin
        case (state)
            A: begin
                if      (r[0])         nstate = B;
                else if (r[1])         nstate = C;
                else if (r[2])         nstate = D;
                else                   nstate = A;
            end
            B: begin
                nstate = (r[0]) ? B : A;
            end
            C: begin
                nstate = (r[1]) ? C : A;
            end
            D: begin
                nstate = (r[2]) ? D : A;
            end
            default: nstate = A;
        endcase
    end

    // Stage 0 — State flip-flops
    always @(posedge clk) begin
        if (!resetn)
            state <= A;
        else
            state <= nstate;
    end

    // Stage 0 — Output decode (continuous assignment)
    assign g = (state == B) ? 3'b001 :
               (state == C) ? 3'b010 :
               (state == D) ? 3'b100 :
                              3'b000;

endmodule
