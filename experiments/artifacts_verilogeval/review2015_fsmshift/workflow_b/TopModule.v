// FSM controlling shift register enable
// After reset, assert shift_ena for exactly 4 cycles, then 0 forever

module TopModule (
    input  wire clk,
    input  wire reset,
    output reg  shift_ena
);

    // State encoding
    localparam IDLE   = 3'd0;
    localparam SHIFT1 = 3'd1;
    localparam SHIFT2 = 3'd2;
    localparam SHIFT3 = 3'd3;
    localparam SHIFT4 = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    // Next-state logic (combinational)
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   next_state = reset ? SHIFT1 : IDLE;
            SHIFT1: next_state = SHIFT2;
            SHIFT2: next_state = SHIFT3;
            SHIFT3: next_state = SHIFT4;
            SHIFT4: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // State update (sequential)
    always @(posedge clk) begin
        if (reset)
            state <= SHIFT1;
        else
            state <= next_state;
    end

    // Output logic
    always @(posedge clk) begin
        if (reset)
            shift_ena <= 1'b1;
        else
            shift_ena <= (next_state == SHIFT1 || next_state == SHIFT2 ||
                          next_state == SHIFT3 || next_state == SHIFT4);
    end

endmodule
