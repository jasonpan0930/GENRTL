// TopModule — 2013_q2bfsm (VerilogEval #139)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input  clk,
    input  resetn,
    input  x,
    input  y,
    output reg f,
    output reg g
);

    // FSM state encoding
    localparam A      = 4'd0,
               S_F    = 4'd1,
               S_X0   = 4'd2,
               S_X1   = 4'd3,
               S_X2   = 4'd4,
               S_G0   = 4'd5,
               S_G1   = 4'd6,
               G_PERM = 4'd7,
               G_ZERO = 4'd8;

    // Stage 0 — State register
    reg [3:0] state;

    // Stage 0 — Next-state and output combinational logic
    reg [3:0] nstate;
    reg       f_next;
    reg       g_next;

    always @(*) begin
        nstate = A;
        f_next = 1'b0;
        g_next = 1'b0;

        if (!resetn) begin
            nstate = A;
            f_next = 1'b0;
            g_next = 1'b0;
        end else begin
            case (state)
                A: begin
                    nstate = S_F;
                    f_next = 1'b0;
                    g_next = 1'b0;
                end
                S_F: begin
                    nstate = S_X0;
                    f_next = 1'b1;
                    g_next = 1'b0;
                end
                S_X0: begin
                    if (x)
                        nstate = S_X1;
                    else
                        nstate = S_X0;
                    f_next = 1'b0;
                    g_next = 1'b0;
                end
                S_X1: begin
                    if (x)
                        nstate = S_X1;
                    else
                        nstate = S_X2;
                    f_next = 1'b0;
                    g_next = 1'b0;
                end
                S_X2: begin
                    if (x)
                        nstate = S_G0;
                    else
                        nstate = S_X0;
                    f_next = 1'b0;
                    g_next = 1'b0;
                end
                S_G0: begin
                    f_next = 1'b0;
                    g_next = 1'b1;
                    if (y)
                        nstate = G_PERM;
                    else
                        nstate = S_G1;
                end
                S_G1: begin
                    f_next = 1'b0;
                    g_next = 1'b1;
                    if (y)
                        nstate = G_PERM;
                    else
                        nstate = G_ZERO;
                end
                G_PERM: begin
                    nstate = G_PERM;
                    f_next = 1'b0;
                    g_next = 1'b1;
                end
                G_ZERO: begin
                    nstate = G_ZERO;
                    f_next = 1'b0;
                    g_next = 1'b0;
                end
                default: begin
                    nstate = A;
                    f_next = 1'b0;
                    g_next = 1'b0;
                end
            endcase
        end
    end

    // Stage 0 — Sequential updates
    always @(posedge clk) begin
        if (!resetn) begin
            state <= A;
            f     <= 1'b0;
            g     <= 1'b0;
        end else begin
            state <= nstate;
            f     <= f_next;
            g     <= g_next;
        end
    end

endmodule
