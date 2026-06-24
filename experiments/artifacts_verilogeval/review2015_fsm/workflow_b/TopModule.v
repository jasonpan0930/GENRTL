// review2015_fsm (VerilogEval #151)
// TopModule: Timer FSM — detect 1101, shift 4, count, done+ack
// Positive-edge clock, synchronous active-high reset

module TopModule (
    input  clk,
    input  reset,
    input  data,
    input  done_counting,
    input  ack,
    output shift_ena,
    output counting,
    output done
);

    localparam S      = 4'd0;
    localparam S1     = 4'd1;
    localparam S11    = 4'd2;
    localparam S110   = 4'd3;
    localparam SHIFT0 = 4'd4;
    localparam SHIFT1 = 4'd5;
    localparam SHIFT2 = 4'd6;
    localparam SHIFT3 = 4'd7;
    localparam COUNT  = 4'd8;
    localparam DONE   = 4'd9;

    reg [3:0] state;
    reg [3:0] next_state;

    // Sequential
    always @(posedge clk) begin
        if (reset)
            state <= S;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            S:      next_state = data ? S1 : S;
            S1:     next_state = data ? S11 : S;
            S11:    next_state = data ? S11 : S110;
            S110:   next_state = data ? SHIFT0 : S;
            SHIFT0: next_state = SHIFT1;
            SHIFT1: next_state = SHIFT2;
            SHIFT2: next_state = SHIFT3;
            SHIFT3: next_state = COUNT;
            COUNT:  next_state = done_counting ? DONE : COUNT;
            DONE:   next_state = ack ? S : DONE;
            default: next_state = S;
        endcase
    end

    // Output logic (Moore)
    assign shift_ena = (state >= SHIFT0) && (state <= SHIFT3);
    assign counting  = (state == COUNT);
    assign done      = (state == DONE);

endmodule
