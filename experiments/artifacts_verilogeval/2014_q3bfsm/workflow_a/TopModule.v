// TopModule: FSM with state-assigned table
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk   - clock (positive edge)
//   reset - synchronous active-high reset
//   x     - input
//   z     - output

module TopModule (
    input clk,
    input reset,
    input x,
    output reg z
);

    reg [2:0] state, next;

    // Next state and output logic
    always @(*) begin
        case (state)
            3'd0: begin next = x ? 3'd1 : 3'd0; z = 1'b0; end  // 000
            3'd1: begin next = x ? 3'd4 : 3'd1; z = 1'b0; end  // 001
            3'd2: begin next = x ? 3'd1 : 3'd2; z = 1'b0; end  // 010
            3'd3: begin next = x ? 3'd2 : 3'd1; z = 1'b1; end  // 011
            3'd4: begin next = x ? 3'd4 : 3'd3; z = 1'b1; end  // 100
            default: begin next = 3'd0;          z = 1'b0; end
        endcase
    end

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= 3'd0;
        else
            state <= next;
    end

endmodule
