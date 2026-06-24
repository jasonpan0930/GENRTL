// Water reservoir level controller FSM
module TopModule (
    input        clk,
    input        reset,
    input  [2:0] s,
    output       fr2,
    output       fr1,
    output       fr0,
    output reg   dfr
);

    // State encoding: 2-bit representing water level
    // 00 = below s[0] (all sensors off)
    // 01 = between s[0] and s[1] (only s[0] on)
    // 10 = between s[1] and s[2] (s[0],s[1] on)
    // 11 = above s[2] (all on)
    reg [1:0] state, next_state;

    // Next state = current sensor reading
    always @(*) begin
        case (s)
            3'b000: next_state = 2'b00;
            3'b001: next_state = 2'b01;
            3'b011: next_state = 2'b10;
            3'b111: next_state = 2'b11;
            default: next_state = state;
        endcase
    end

    // State register with active-high sync reset
    reg [1:0] prev_state;
    always @(posedge clk) begin
        if (reset) begin
            state <= 2'b00;
            prev_state <= 2'b00;
            dfr <= 1'b1;
        end else begin
            prev_state <= state;
            state <= next_state;
            dfr <= (next_state > state) ? 1'b1 : 1'b0;
        end
    end

    // Moore outputs
    assign fr0 = (state != 2'b11);
    assign fr1 = (state == 2'b00 || state == 2'b01);
    assign fr2 = (state == 2'b00);

endmodule
