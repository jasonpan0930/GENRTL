module TopModule (
    input  wire clk,
    input  wire reset,
    input  wire in,
    output wire done
);

    // ── FSM state encoding ──
    localparam [3:0]
        IDLE = 4'd0,
        B0   = 4'd1,
        B1   = 4'd2,
        B2   = 4'd3,
        B3   = 4'd4,
        B4   = 4'd5,
        B5   = 4'd6,
        B6   = 4'd7,
        B7   = 4'd8,
        STOP = 4'd9,
        WAIT = 4'd10;

    // ── Internal signal declarations (per domain_knowledge §1: declare before use) ──
    reg  [3:0] state;
    wire [3:0] nstate;
    wire done_w;
    reg done_r;

    // ── Sequential block: state register (Stage 0, posedge clk, sync active-high reset) ──
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= nstate;
    end

    // ── Combinational: next-state logic ──
    assign nstate =
        (state == IDLE && in == 1'b0) ? B0
      : (state == IDLE && in == 1'b1) ? IDLE
      : (state == B0)                  ? B1
      : (state == B1)                  ? B2
      : (state == B2)                  ? B3
      : (state == B3)                  ? B4
      : (state == B4)                  ? B5
      : (state == B5)                  ? B6
      : (state == B6)                  ? B7
      : (state == B7)                  ? STOP
      : (state == STOP && in == 1'b1)  ? IDLE
      : (state == STOP && in == 1'b0)  ? WAIT
      : (state == WAIT && in == 1'b1)  ? IDLE
      : (state == WAIT && in == 1'b0)  ? WAIT
      :                                  IDLE;

    // ── Combinational: output logic ──
    assign done_w = (state == STOP) && (in == 1'b1);
    assign done = done_r;
    always @(posedge clk) begin
        if (reset)
            done_r <= 1'b0;
        else 
            done_r <= done_w;
    end

endmodule
