// Lemmings game FSM — walk left/right with bump sensors
// Asynchronous reset, active-high

module TopModule (
    input  wire clk,
    input  wire areset,
    input  wire bump_left,
    input  wire bump_right,
    output wire walk_left,
    output wire walk_right
);

    reg state;
    reg next_state;

    localparam LEFT  = 1'b0;
    localparam RIGHT = 1'b1;

    // Next-state logic
    always @(*) begin
        case ({bump_left, bump_right})
            2'b00:   next_state = state;
            2'b01:   next_state = LEFT;   // bumped right → walk left
            2'b10:   next_state = RIGHT;  // bumped left → walk right
            2'b11:   next_state = (state == LEFT) ? RIGHT : LEFT;  // both → switch
            default: next_state = LEFT;
        endcase
    end

    // State update with async reset
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= LEFT;
        else
            state <= next_state;
    end

    // Moore outputs
    assign walk_left  = (state == LEFT);
    assign walk_right = (state == RIGHT);

endmodule
