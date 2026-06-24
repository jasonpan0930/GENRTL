// Full FSM — 6 states (A=000...F=101), w/1 transitions
// Reset to A, z=1 for E and F

module TopModule (
    input  wire       clk,
    input  wire       reset,
    input  wire       w,
    output wire       z
);

    localparam A = 3'd0, B = 3'd1, C = 3'd2;
    localparam D = 3'd3, E = 3'd4, F = 3'd5;

    reg [2:0] state;

    // Next-state logic
    reg [2:0] next;
    always @(*) begin
        case (state)
            A: next = w ? B : A;
            B: next = w ? C : D;
            C: next = w ? E : D;
            D: next = w ? F : A;
            E: next = w ? E : D;
            F: next = w ? C : D;
            default: next = A;
        endcase
    end

    // State flip-flops
    always @(posedge clk) begin
        if (reset)
            state <= A;
        else
            state <= next;
    end

    // Output
    assign z = (state == E || state == F);

endmodule
