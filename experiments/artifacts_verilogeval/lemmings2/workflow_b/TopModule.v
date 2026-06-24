// lemmings2 (VerilogEval #142)
// TopModule: Lemmings FSM with walking, bump turn, and falling
// Asynchronous active-high reset, positive-edge clock

module TopModule (
    input  clk,
    input  areset,
    input  bump_left,
    input  bump_right,
    input  ground,
    output walk_left,
    output walk_right,
    output aaah
);

    localparam WALK_LEFT  = 2'd0;
    localparam WALK_RIGHT = 2'd1;
    localparam FALL_LEFT  = 2'd2;
    localparam FALL_RIGHT = 2'd3;

    reg [1:0] state;
    reg [1:0] next_state;

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
                else if (bump_left)
                    next_state = WALK_RIGHT;
                else
                    next_state = WALK_LEFT;
            WALK_RIGHT:
                if (!ground)
                    next_state = FALL_RIGHT;
                else if (bump_right)
                    next_state = WALK_LEFT;
                else
                    next_state = WALK_RIGHT;
            FALL_LEFT:
                next_state = ground ? WALK_LEFT : FALL_LEFT;
            FALL_RIGHT:
                next_state = ground ? WALK_RIGHT : FALL_RIGHT;
            default:
                next_state = WALK_LEFT;
        endcase
    end

    // Output logic (Moore)
    assign walk_left  = (state == WALK_LEFT);
    assign walk_right = (state == WALK_RIGHT);
    assign aaah       = (state == FALL_LEFT) || (state == FALL_RIGHT);

endmodule
