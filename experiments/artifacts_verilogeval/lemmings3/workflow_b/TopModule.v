// lemmings3 (VerilogEval #152)
// TopModule: Lemmings FSM with walking, falling, and digging
// Asynchronous active-high reset, positive-edge clock

module TopModule (
    input  clk,
    input  areset,
    input  bump_left,
    input  bump_right,
    input  ground,
    input  dig,
    output walk_left,
    output walk_right,
    output aaah,
    output digging
);

    localparam WALK_LEFT  = 3'd0;
    localparam WALK_RIGHT = 3'd1;
    localparam FALL_LEFT  = 3'd2;
    localparam FALL_RIGHT = 3'd3;
    localparam DIG_LEFT   = 3'd4;
    localparam DIG_RIGHT  = 3'd5;

    reg [2:0] state;
    reg [2:0] next_state;

    // Sequential with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= WALK_LEFT;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            WALK_LEFT:
                if (!ground)
                    next_state = FALL_LEFT;
                else if (dig)
                    next_state = DIG_LEFT;
                else if (bump_left)
                    next_state = WALK_RIGHT;
                else
                    next_state = WALK_LEFT;
            WALK_RIGHT:
                if (!ground)
                    next_state = FALL_RIGHT;
                else if (dig)
                    next_state = DIG_RIGHT;
                else if (bump_right)
                    next_state = WALK_LEFT;
                else
                    next_state = WALK_RIGHT;
            FALL_LEFT:
                next_state = ground ? WALK_LEFT : FALL_LEFT;
            FALL_RIGHT:
                next_state = ground ? WALK_RIGHT : FALL_RIGHT;
            DIG_LEFT:
                next_state = ground ? DIG_LEFT : FALL_LEFT;
            DIG_RIGHT:
                next_state = ground ? DIG_RIGHT : FALL_RIGHT;
            default:
                next_state = WALK_LEFT;
        endcase
    end

    // Output logic (Moore)
    assign walk_left  = (state == WALK_LEFT);
    assign walk_right = (state == WALK_RIGHT);
    assign aaah       = (state == FALL_LEFT) || (state == FALL_RIGHT);
    assign digging    = (state == DIG_LEFT)  || (state == DIG_RIGHT);

endmodule
