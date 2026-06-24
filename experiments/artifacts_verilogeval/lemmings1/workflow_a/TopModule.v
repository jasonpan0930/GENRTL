// TopModule: Lemmings FSM (walk left/right, switch on bump)
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk        - clock (positive edge)
//   areset     - asynchronous active-high reset (to walk left)
//   bump_left  - bumped on the left
//   bump_right - bumped on the right
//   walk_left  - walking left
//   walk_right - walking right

module TopModule (
    input  clk,
    input  areset,
    input  bump_left,
    input  bump_right,
    output walk_left,
    output walk_right
);

    reg state, next;

    localparam LEFT  = 1'b0,
               RIGHT = 1'b1;

    // Next state logic
    always @(*) begin
        case (state)
            LEFT:  next = (bump_left | bump_right) ? RIGHT : LEFT;
            RIGHT: next = (bump_left | bump_right) ? LEFT  : RIGHT;
        endcase
    end

    // State register with async reset
    always @(posedge clk, posedge areset) begin
        if (areset)
            state <= LEFT;
        else
            state <= next;
    end

    // Moore outputs
    assign walk_left  = (state == LEFT);
    assign walk_right = (state == RIGHT);

endmodule
