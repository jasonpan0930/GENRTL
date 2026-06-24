// lemmings4 (VerilogEval #155)
// TopModule: Lemmings FSM — walk, fall, dig, splatter
// Asynchronous active-high reset, posedge clk

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
    localparam SPLAT      = 3'd6;

    reg [2:0] state;
    reg [2:0] next_state;
    reg [4:0] fall_cnt;
    reg [4:0] next_fall_cnt;

    // Sequential with async reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state    <= WALK_LEFT;
            fall_cnt <= 5'd0;
        end else begin
            state    <= next_state;
            fall_cnt <= next_fall_cnt;
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            WALK_LEFT: begin
                if (!ground) begin
                    next_state    = FALL_LEFT;
                    next_fall_cnt = 5'd0;
                end else if (dig) begin
                    next_state    = DIG_LEFT;
                    next_fall_cnt = fall_cnt;
                end else if (bump_left) begin
                    next_state    = WALK_RIGHT;
                    next_fall_cnt = fall_cnt;
                end else begin
                    next_state    = WALK_LEFT;
                    next_fall_cnt = fall_cnt;
                end
            end
            WALK_RIGHT: begin
                if (!ground) begin
                    next_state    = FALL_RIGHT;
                    next_fall_cnt = 5'd0;
                end else if (dig) begin
                    next_state    = DIG_RIGHT;
                    next_fall_cnt = fall_cnt;
                end else if (bump_right) begin
                    next_state    = WALK_LEFT;
                    next_fall_cnt = fall_cnt;
                end else begin
                    next_state    = WALK_RIGHT;
                    next_fall_cnt = fall_cnt;
                end
            end
            FALL_LEFT: begin
                next_fall_cnt = fall_cnt + 5'd1;
                if (ground) begin
                    if (fall_cnt > 5'd20)
                        next_state = SPLAT;
                    else
                        next_state = WALK_LEFT;
                end else begin
                    next_state = FALL_LEFT;
                end
            end
            FALL_RIGHT: begin
                next_fall_cnt = fall_cnt + 5'd1;
                if (ground) begin
                    if (fall_cnt > 5'd20)
                        next_state = SPLAT;
                    else
                        next_state = WALK_RIGHT;
                end else begin
                    next_state = FALL_RIGHT;
                end
            end
            DIG_LEFT: begin
                next_fall_cnt = fall_cnt;
                if (!ground) begin
                    next_state    = FALL_LEFT;
                    next_fall_cnt = 5'd0;
                end else begin
                    next_state = DIG_LEFT;
                end
            end
            DIG_RIGHT: begin
                next_fall_cnt = fall_cnt;
                if (!ground) begin
                    next_state    = FALL_RIGHT;
                    next_fall_cnt = 5'd0;
                end else begin
                    next_state = DIG_RIGHT;
                end
            end
            default: begin  // SPLAT or invalid
                next_state    = SPLAT;
                next_fall_cnt = fall_cnt;
            end
        endcase
    end

    // Output logic (Moore)
    assign walk_left  = (state == WALK_LEFT);
    assign walk_right = (state == WALK_RIGHT);
    assign aaah       = (state == FALL_LEFT) || (state == FALL_RIGHT);
    assign digging    = (state == DIG_LEFT)  || (state == DIG_RIGHT);

endmodule
