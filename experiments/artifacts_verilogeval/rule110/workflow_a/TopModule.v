// TopModule: Rule 110 cellular automaton, 512 cells
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk        - clock (positive edge)
//   load       - synchronous active-high load
//   data[511:0] - load data
//   q[511:0]   - current state

module TopModule (
    input         clk,
    input         load,
    input  [511:0] data,
    output reg [511:0] q
);

    wire [511:0] next;

    genvar i;
    generate
        for (i = 0; i < 512; i = i + 1) begin : gen_rule110
            wire left   = (i == 0)   ? 1'b0 : q[i-1];
            wire center = q[i];
            wire right  = (i == 511) ? 1'b0 : q[i+1];
            // Rule 110 truth table:
            // 111→0, 110→1, 101→1, 100→0, 011→1, 010→1, 001→1, 000→0
            assign next[i] = (center & ~right) | (~left & center) | (~left & right) | (left & ~center & right);
        end
    endgenerate

    always @(posedge clk) begin
        if (load)
            q <= data;
        else
            q <= next;
    end

endmodule
