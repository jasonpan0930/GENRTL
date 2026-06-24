// Combinational next-state logic for y[1] (Y1)
// Binary encoded FSM: A=000, B=001, C=010, D=011, E=100, F=101

module TopModule (
    input  [2:0] y,
    input        w,
    output       Y1
);

    reg [2:0] next;
    always @(*) begin
        case (y)
            3'b000: next = w ? 3'b000 : 3'b001;  // A: w=1→A, w=0→B
            3'b001: next = w ? 3'b011 : 3'b010;  // B: w=1→D, w=0→C
            3'b010: next = w ? 3'b011 : 3'b100;  // C: w=1→D, w=0→E
            3'b011: next = w ? 3'b000 : 3'b101;  // D: w=1→A, w=0→F
            3'b100: next = w ? 3'b011 : 3'b100;  // E: w=1→D, w=0→E
            3'b101: next = w ? 3'b011 : 3'b010;  // F: w=1→D, w=0→C
            default: next = 3'b000;
        endcase
    end
    assign Y1 = next[1];

endmodule
