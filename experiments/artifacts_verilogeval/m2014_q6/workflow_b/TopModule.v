// Full FSM implementation — 6 states, binary encoding A=000...F=101
// Reset to A, output z=1 for states E and F

module TopModule (
    input  wire       clk,
    input  wire       reset,
    input  wire       w,
    output reg        z
);

    reg [2:0] state;

    // State codes
    localparam A = 3'b000, B = 3'b001, C = 3'b010;
    localparam D = 3'b011, E = 3'b100, F = 3'b101;

    always @(posedge clk) begin
        if (reset) begin
            state <= A;
        end else begin
            case (state)
                A: state <= w ? A : B;
                B: state <= w ? D : C;
                C: state <= w ? D : E;
                D: state <= w ? A : F;
                E: state <= w ? D : E;
                F: state <= w ? D : C;
                default: state <= A;
            endcase
        end
    end

    // Moore output
    always @(*) begin
        case (state)
            E, F: z = 1'b1;
            default: z = 1'b0;
        endcase
    end

endmodule
