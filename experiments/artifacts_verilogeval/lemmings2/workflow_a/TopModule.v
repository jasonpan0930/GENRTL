// Lemmings 2 — Moore FSM with fall direction memory
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

    localparam WL = 2'd0;  // Walk Left
    localparam WR = 2'd1;  // Walk Right
    localparam FL = 2'd2;  // Fall Left (remembers direction)
    localparam FR = 2'd3;  // Fall Right

    reg [1:0] state, next_state;

    // State register with async reset
    always @(posedge clk, posedge areset) begin
        if (areset)
            state <= WL;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            WL: begin
                if (!ground)
                    next_state = FL;
                else if (bump_left)
                    next_state = WR;
                // else stay WL
            end
            WR: begin
                if (!ground)
                    next_state = FR;
                else if (bump_right)
                    next_state = WL;
                // else stay WR
            end
            FL: begin
                if (ground)
                    next_state = WL;
                // else stay FL (bumps ignored while falling)
            end
            FR: begin
                if (ground)
                    next_state = WR;
                // else stay FR (bumps ignored while falling)
            end
        endcase
    end

    // Moore outputs
    assign walk_left  = (state == WL);
    assign walk_right = (state == WR);
    assign aaah       = (state == FL || state == FR);

endmodule
