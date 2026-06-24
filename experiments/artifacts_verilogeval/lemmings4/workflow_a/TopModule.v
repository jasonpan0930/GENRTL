// Lemmings 4 — Moore FSM with fall timer and splatter
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

    localparam WL     = 3'd0;
    localparam WR     = 3'd1;
    localparam FL     = 3'd2;
    localparam FR     = 3'd3;
    localparam DIG_L  = 3'd4;
    localparam DIG_R  = 3'd5;
    localparam SPLAT  = 3'd6;

    reg [2:0] state, next_state;
    reg [5:0] fall_cnt;  // enough for >20

    // State register
    always @(posedge clk, posedge areset) begin
        if (areset)
            state <= WL;
        else
            state <= next_state;
    end

    // Fall counter
    always @(posedge clk, posedge areset) begin
        if (areset)
            fall_cnt <= 6'd0;
        else if (state == FL || state == FR)
            fall_cnt <= fall_cnt + 1'b1;
        else
            fall_cnt <= 6'd0;
    end

    // Next state logic
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
                if (ground) begin
                    if (fall_cnt > 6'd20)
                        next_state = SPLAT;
                    else
                        next_state = WL;
                end
            end
            FR: begin
                if (ground) begin
                    if (fall_cnt > 6'd20)
                        next_state = SPLAT;
                    else
                        next_state = WR;
                end
            end
            DIG_L: begin
                if (!ground)
                    next_state = FL;
            end
            DIG_R: begin
                if (!ground)
                    next_state = FR;
            end
            SPLAT: next_state = SPLAT;  // forever
        endcase
    end

    // Moore outputs (all 0 in SPLAT)
    assign walk_left  = (state == WL);
    assign walk_right = (state == WR);
    assign aaah       = (state == FL || state == FR);
    assign digging    = (state == DIG_L || state == DIG_R);

endmodule
