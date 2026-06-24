// circuit10 (VerilogEval #147)
// TopModule: 1-bit state machine derived from waveforms
// q = state ^ a ^ b, next_state = state ? (a|b) : (a&b)
// No reset signal in original SPEC

module TopModule (
    input  clk,
    input  a,
    input  b,
    output q,
    output state
);

    reg state;

    wire next_state;
    assign next_state = state ? (a | b) : (a & b);
    assign q = state ^ a ^ b;

    always @(posedge clk) begin
        state <= next_state;
    end

endmodule
