// Fancy timer: detect 1101, shift 4-bit delay (MSB first), count (delay+1)*1000
module TopModule (
    input        clk,
    input        reset,
    input        data,
    output reg [3:0] count,
    output       counting,
    output reg   done,
    input        ack
);

    localparam S      = 4'd0;
    localparam S1     = 4'd1;
    localparam S11    = 4'd2;
    localparam S110   = 4'd3;
    localparam SHIFT  = 4'd4;
    localparam CNT    = 4'd5;
    localparam DONE   = 4'd6;

    reg [3:0] state, next_state;
    reg [3:0] delay;
    reg [9:0] cycle_cnt;
    reg [3:0] delay_cnt;
    reg [3:0] shift_reg;
    reg [1:0] shift_cnt;

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= S;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            S:      next_state = data ? S1    : S;
            S1:     next_state = data ? S11   : S;
            S11:    next_state = data ? S11   : S110;
            S110:   next_state = data ? SHIFT : S;
            SHIFT:  next_state = (shift_cnt == 2'd3) ? CNT : SHIFT;
            CNT:    next_state = (cycle_cnt == 999 && delay_cnt == 0) ? DONE : CNT;
            DONE:   next_state = ack ? S : DONE;
        endcase
    end

    // Data path
    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 4'd0;
            shift_cnt <= 2'd0;
            delay <= 4'd0;
            cycle_cnt <= 10'd0;
            delay_cnt <= 4'd0;
            count <= 4'd0;
            done <= 1'b0;
        end else begin
            case (state)
                S110: begin
                    // prepare for shift on next cycle
                    shift_cnt <= 2'd0;
                    shift_reg <= 4'd0;
                end
                SHIFT: begin
                    shift_reg <= {shift_reg[2:0], data};  // MSB first
                    if (shift_cnt == 2'd3)
                        delay <= {shift_reg[2:0], data};  // capture final
                    shift_cnt <= shift_cnt + 1'b1;
                end
                CNT: begin
                    if (cycle_cnt == 999) begin
                        cycle_cnt <= 10'd0;
                        if (delay_cnt > 0)
                            delay_cnt <= delay_cnt - 1'b1;
                    end else begin
                        cycle_cnt <= cycle_cnt + 1'b1;
                    end
                end
                DONE: done <= 1'b1;
            endcase
            // Init delay_cnt on entering CNT
            if (next_state == CNT && state != CNT) begin
                delay_cnt <= delay;
                cycle_cnt <= 10'd0;
            end
            // Clear done on leaving DONE
            if (state == DONE && next_state != DONE)
                done <= 1'b0;
        end
    end

    // count output
    always @(*) begin
        if (state == CNT)
            count = delay_cnt;
        else
            count = 4'd0;
    end

    assign counting = (state == CNT);

endmodule
