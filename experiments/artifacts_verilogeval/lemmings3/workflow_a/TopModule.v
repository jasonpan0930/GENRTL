// Lemmings 3 — Moore FSM with walking, falling, and digging
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

    localparam WL    = 3'd0;  // Walk Left
    localparam WR    = 3'd1;  // Walk Right
    localparam FL    = 3'd2;  // Fall Left
    localparam FR    = 3'd3;  // Fall Right
    localparam DIG_L = 3'd4;  // Digging Left
    localparam DIG_R = 3'd5;  // Digging Right

    reg [2:0] state, next_state;

    // State register with async reset
    always @(posedge clk, posedge areset) begin
        if (areset)
            state <= WL;
        else
            state <= next_state;
    end

    // Next state logic (priority: fall > dig > bump)
    always @(*) begin
        next_state = state;
        case (state)
            WL: begin
                if (!ground)
                    next_state = FL;
                else if (dig)
                    next_state = DIG_L;
                else if (bump_left)
                    next_state = WR;
            end
            WR: begin
                if (!ground)
                    next_state = FR;
                else if (dig)
                    next_state = DIG_R;
                else if (bump_right)
                    next_state = WL;
            end
            FL: begin
                if (ground)
                    next_state = WL;
            end
            FR: begin
                if (ground)
                    next_state = WR;
            end
            DIG_L: begin
                if (!ground)
                    next_state = FL;
            end
            DIG_R: begin
                if (!ground)
                    next_state = FR;
            end
        endcase
    end

    // Moore outputs
    assign walk_left  = (state == WL);
    assign walk_right = (state == WR);
    assign aaah       = (state == FL || state == FR);
    assign digging    = (state == DIG_L || state == DIG_R);

endmodule
