// TopModule: Moore FSM (states A–F, same machine as Prob099/Prob135)
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
    output reg z
);

    reg [2:0] state, next;

    localparam A = 3'd0,
               B = 3'd1,
               C = 3'd2,
               D = 3'd3,
               E = 3'd4,
               F = 3'd5;

    // Next state and output logic
    always @(*) begin
        case (state)
            A: begin next = w ? A : B; z = 1'b0; end
            B: begin next = w ? D : C; z = 1'b0; end
            C: begin next = w ? D : E; z = 1'b0; end
            D: begin next = w ? A : F; z = 1'b0; end
            E: begin next = w ? D : E; z = 1'b1; end
            F: begin next = w ? D : C; z = 1'b1; end
            default: begin next = A;   z = 1'b0; end
        endcase
    end

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= A;
        else
            state <= next;
    end

endmodule
