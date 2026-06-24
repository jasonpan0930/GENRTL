// TopModule: next-state logic for y[1] (FSM states A–F, binary encoding)
// SPEC: spec/design.spec.txt
//
// Ports:
//   y[2:0] - current state (A=000, B=001, C=010, D=011, E=100, F=101)
//   w      - input
//   Y1     - next state bit y[1]

module TopModule (
    input  [2:0] y,
    input        w,
    output       Y1
);

    reg Y1_reg;

    always @(*) begin
        case (y)
            3'd0: Y1_reg = 1'b0;                          // A
            3'd1: Y1_reg = 1'b1;                          // B
            3'd2: Y1_reg = w;                             // C
            3'd3: Y1_reg = 1'b0;                          // D
            3'd4: Y1_reg = w;                             // E
            3'd5: Y1_reg = 1'b1;                          // F
            default: Y1_reg = 1'b0;
        endcase
    end

    assign Y1 = Y1_reg;

endmodule
