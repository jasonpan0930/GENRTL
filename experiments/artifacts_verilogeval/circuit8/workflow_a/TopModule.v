// Circuit derived from spec waveform table:
// - p = one flip-flop, D = (p & (a|b)) | (~p & a & b)
// - q = a ^ b ^ p (combinational)
module TopModule (
    input  clock,
    input  a,
    input  b,
    output reg p,
    output q
);

    wire d = (p & (a | b)) | (~p & a & b);
    assign q = a ^ b ^ p;

    always @(posedge clk) begin
        p <= d;
    end

endmodule
