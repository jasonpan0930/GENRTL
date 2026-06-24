// TopModule — lemmings4 (VerilogEval #155)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input        clk,
    input        areset,
    input        bump_left,
    input        bump_right,
    input        ground,
    input        dig,
    output reg   walk_left,
    output reg   walk_right,
    output reg   aaah,
    output reg   digging
);

    // FSM state encoding
    localparam WALK_L = 3'd0,
               WALK_R = 3'd1,
               FALL   = 3'd2,
               DIG    = 3'd3,
               SPLAT  = 3'd4;

    // Stage 0 — State, direction and fall-counter registers
    reg [2:0] state;
    reg       dir;        // 0=left, 1=right
    reg [4:0] fall_cnt;

    // Stage 0 — Next-state combinational logic
    reg [2:0] nstate;
    reg       dir_next;
    reg [4:0] fall_cnt_next;

    wire bump = bump_left | bump_right;

    always @(*) begin
        nstate = SPLAT;
        dir_next = dir;
        fall_cnt_next = fall_cnt;

        case (state)
            WALK_L: begin
                if (!ground) begin
                    nstate = FALL;
                    dir_next = 1'b0;
                    fall_cnt_next = 5'd0;
                end else if (dig) begin
                    nstate = DIG;
                    dir_next = 1'b0;
                end else if (bump) begin
                    nstate = WALK_R;
                end else begin
                    nstate = WALK_L;
                end
            end
            WALK_R: begin
                if (!ground) begin
                    nstate = FALL;
                    dir_next = 1'b1;
                    fall_cnt_next = 5'd0;
                end else if (dig) begin
                    nstate = DIG;
                    dir_next = 1'b1;
                end else if (bump) begin
                    nstate = WALK_L;
                end else begin
                    nstate = WALK_R;
                end
            end
            FALL: begin
                if (!ground) begin
                    nstate = FALL;
                    fall_cnt_next = fall_cnt + 5'd1;
                end else if (fall_cnt > 5'd20) begin
                    nstate = SPLAT;
                end else begin
                    nstate = (dir) ? WALK_R : WALK_L;
                end
            end
            DIG: begin
                if (!ground) begin
                    nstate = FALL;
                    fall_cnt_next = 5'd0;
                end else begin
                    nstate = DIG;
                end
            end
            SPLAT: begin
                nstate = SPLAT;
            end
            default: begin
                nstate = SPLAT;
            end
        endcase
    end

    // Stage 0 — Output decode (combinational)
    always @(*) begin
        walk_left  = 1'b0;
        walk_right = 1'b0;
        aaah       = 1'b0;
        digging    = 1'b0;

        case (state)
            WALK_L: walk_left = 1'b1;
            WALK_R: walk_right = 1'b1;
            FALL:   aaah = 1'b1;
            DIG:    digging = 1'b1;
            SPLAT:  ; // all zeros
        endcase
    end

    // Stage 0 — Sequential updates (async reset)
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state    <= WALK_L;
            dir      <= 1'b0;
            fall_cnt <= 5'd0;
        end else begin
            state    <= nstate;
            dir      <= dir_next;
            fall_cnt <= fall_cnt_next;
        end
    end

endmodule
