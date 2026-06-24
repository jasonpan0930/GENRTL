// Circuit derived from waveform table:
// - state = one flip-flop, D = majority(a, b, state)
// - q = a ^ b ^ state (combinational)
module TopModule (
    input  clk,
    input  a,
    input  b,
    output q,
    output reg state
);

    wire d = (state & a) | (state & b) | (a & b);
    assign q = a ^ b ^ state;

    always @(posedge clk) begin
        state <= d;
    end

endmodule
