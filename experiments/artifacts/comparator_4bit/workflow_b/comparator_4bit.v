//======================================================================
// comparator_4bit — 4-bit binary comparator (combinational, subtraction-based)
// Outputs: A_greater, A_equal, A_less (mutually exclusive)
//======================================================================

module comparator_4bit (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire       A_greater,
    output wire       A_equal,
    output wire       A_less
);

    // Internal signals
    wire [4:0] diff;      // A - B with borrow (= 5 bits)
    wire       borrow;
    wire       zero;

    // Subtraction: A - B, bit 4 indicates borrow
    assign diff  = A - B;
    assign borrow = diff[4];   // borrow when MSB of 5-bit result is 1

    // Zero detection
    assign zero  = (diff[3:0] == 4'b0000);

    // Output encoding
    assign A_less    = borrow;
    assign A_equal   = ~borrow & zero;
    assign A_greater = ~borrow & ~zero;

endmodule
