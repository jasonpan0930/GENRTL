// HDLC framing FSM — Moore type
// Detects: 0111110 (disc), 01111110 (flag), 01111111... (err)
module TopModule (
    input  clk,
    input  reset,
    input  in,
    output disc,
    output flag,
    output err
);

    localparam S0   = 4'd0;  // just saw a 0 (reset behaves as if previous input was 0)
    localparam S1   = 4'd1;  // saw 01
    localparam S2   = 4'd2;  // saw 011
    localparam S3   = 4'd3;  // saw 0111
    localparam S4   = 4'd4;  // saw 01111
    localparam S5   = 4'd5;  // saw 011111
    localparam DISC = 4'd6;  // saw 0111110  -> assert disc
    localparam S6   = 4'd7;  // saw 0111111
    localparam FLAG = 4'd8;  // saw 01111110 -> assert flag
    localparam ERR  = 4'd9;  // saw 01111111... -> assert err

    reg [3:0] state, next_state;

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    // Next state logic (combinational)
    always @(*) begin
        next_state = state;
        case (state)
            S0:   next_state = in ? S1   : S0;
            S1:   next_state = in ? S2   : S0;
            S2:   next_state = in ? S3   : S0;
            S3:   next_state = in ? S4   : S0;
            S4:   next_state = in ? S5   : S0;
            S5:   next_state = in ? S6   : DISC;
            DISC: next_state = in ? S1   : S0;
            S6:   next_state = in ? ERR  : FLAG;
            FLAG: next_state = in ? S1   : S0;
            ERR:  next_state = in ? ERR  : S0;
            default: next_state = S0;
        endcase
    end

    // Moore outputs
    assign disc = (state == DISC);
    assign flag = (state == FLAG);
    assign err  = (state == ERR);

endmodule
