// TopModule: next-state (Y0) and output (z) logic for FSM
// SPEC: spec/design.spec.txt
//
// Ports:
//   x     - input
//   y[2:0] - present state
//   Y0    - bit 0 of next state Y[2:0]
//   z     - output

module TopModule (
    input        x,
    input  [2:0] y,
    output       Y0,
    output       z
);

    reg [2:0] next;
    reg       z_reg;

    always @(*) begin
        case (y)
            3'd0: begin next = x ? 3'd1 : 3'd0; z_reg = 1'b0; end
            3'd1: begin next = x ? 3'd4 : 3'd1; z_reg = 1'b0; end
            3'd2: begin next = x ? 3'd1 : 3'd2; z_reg = 1'b0; end
            3'd3: begin next = x ? 3'd2 : 3'd1; z_reg = 1'b1; end
            3'd4: begin next = x ? 3'd4 : 3'd3; z_reg = 1'b1; end
            default: begin next = 3'd0; z_reg = 1'b0; end
        endcase
    end

    assign Y0 = next[0];
    assign z  = z_reg;

endmodule
