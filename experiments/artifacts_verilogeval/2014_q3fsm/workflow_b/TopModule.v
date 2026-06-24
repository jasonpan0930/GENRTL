// TopModule — 2014_q3fsm (VerilogEval #133)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input  clk,
    input  reset,
    input  s,
    input  w,
    output reg z
);

    // FSM state encoding
    localparam A  = 3'b000,
               B0 = 3'b001,
               B1 = 3'b010,
               B2 = 3'b011,
               B3 = 3'b100;

    // Stage 0 — State register and counter
    reg [2:0] state;
    reg [1:0] cnt;

    // Stage 0 — Next-state combinational logic
    reg [2:0] nstate;
    reg [1:0] cnt_next;
    reg       z_next;

    always @(*) begin
        nstate = A;
        cnt_next = cnt;
        z_next = 1'b0;

        case (state)
            A: begin
                if (reset)
                    nstate = A;
                else if (s)
                    nstate = B0;
                else
                    nstate = A;
                z_next = 1'b0;
            end
            B0: begin
                nstate = B1;
                cnt_next = w ? 2'd1 : 2'd0;
                z_next = 1'b0;
            end
            B1: begin
                nstate = B2;
                cnt_next = cnt + (w ? 2'd1 : 2'd0);
                z_next = 1'b0;
            end
            B2: begin
                nstate = B3;
                cnt_next = cnt + (w ? 2'd1 : 2'd0);
                z_next = 1'b0;
            end
            B3: begin
                nstate = B0;
                cnt_next = cnt;
                z_next = (cnt == 2'd2) ? 1'b1 : 1'b0;
            end
            default: begin
                nstate = A;
                cnt_next = 2'd0;
                z_next = 1'b0;
            end
        endcase
    end

    // Stage 0 — Sequential updates
    always @(posedge clk) begin
        if (reset) begin
            state <= A;
            cnt   <= 2'd0;
            z     <= 1'b0;
        end else begin
            state <= nstate;
            cnt   <= cnt_next;
            z     <= z_next;
        end
    end

endmodule
