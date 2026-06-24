// TopModule: Moore FSM (states A–F)
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk   - clock (positive edge)
//   reset - synchronous active-high reset
//   w     - input
//   z     - Moore output

module TopModule (
    input clk,
    input reset,
    input w,
    output z
);

    reg [2:0] state, next;

    localparam A = 3'd0,
               B = 3'd1,
               C = 3'd2,
               D = 3'd3,
               E = 3'd4,
               F = 3'd5;

    // Next state logic
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

    // Moore output
    assign z = (state == E) | (state == F);

endmodule
