// TopModule — fsm_hdlc (VerilogEval #140)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input  clk,
    input  reset,
    input  in,
    output disc,
    output flag,
    output err
);

    // FSM state encoding
    localparam IDLE  = 4'd0,
               ONE   = 4'd1,
               TWO   = 4'd2,
               THREE = 4'd3,
               FOUR  = 4'd4,
               FIVE  = 4'd5,
               SIX   = 4'd6,
               DISC  = 4'd7,
               FLAG  = 4'd8,
               ERR   = 4'd9;

    // Stage 0 — State register
    reg [3:0] state;

    // Stage 0 — Output decode (combinational)
    assign disc = (state == DISC);
    assign flag = (state == FLAG);
    assign err  = (state == ERR);

    // Stage 0 — Next-state logic (combinational)
    reg [3:0] nstate;

    always @(*) begin
        case (state)
            IDLE:  nstate = in ? ONE   : IDLE;
            ONE:   nstate = in ? TWO   : IDLE;
            TWO:   nstate = in ? THREE : IDLE;
            THREE: nstate = in ? FOUR  : IDLE;
            FOUR:  nstate = in ? FIVE  : IDLE;
            FIVE:  nstate = in ? SIX   : DISC;
            SIX:   nstate = in ? ERR   : FLAG;
            DISC:  nstate = in ? ONE   : IDLE;
            FLAG:  nstate = in ? ONE   : IDLE;
            ERR:   nstate = in ? ERR   : IDLE;
            default: nstate = IDLE;
        endcase
    end

    // Stage 0 — Sequential update
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= nstate;
    end

endmodule
