module sub_64bit (
    input  [63:0] A,        // First 64-bit signed operand
    input  [63:0] B,        // Second 64-bit signed operand (subtracted from A)
    output [63:0] result,   // A - B
    output        overflow  // Signed overflow flag
);

    wire [63:0] diff;

    assign diff = A - B;

    // Overflow detection:
    // - Positive overflow: A >= 0, B < 0, result < 0
    // - Negative overflow: A < 0, B >= 0, result >= 0
    assign overflow = (~A[63] & B[63] & diff[63]) | (A[63] & ~B[63] & ~diff[63]);

    assign result = diff;

endmodule
