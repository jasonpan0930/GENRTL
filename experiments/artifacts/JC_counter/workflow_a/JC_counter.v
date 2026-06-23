// JC_counter: 64-bit Johnson (torsional ring) counter
//
// SPEC: spec/design.spec.txt
// Module: JC_counter
//
// Ports:
//   clk   - Clock (posedge)
//   rst_n - Active-low asynchronous reset
//   Q     - 64-bit counter output
//
// Behavior:
//   On reset (rst_n low): Q = 0
//   If Q[0] == 0: shift right, append 1 at MSB  -> {1'b1, Q[63:1]}
//   If Q[0] == 1: shift right, append 0 at MSB  -> {1'b0, Q[63:1]}

module JC_counter (
    input        clk,
    input        rst_n,
    output reg [63:0] Q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Q <= 64'h0;
        end else begin
            Q <= {~Q[0], Q[63:1]};
        end
    end

endmodule
