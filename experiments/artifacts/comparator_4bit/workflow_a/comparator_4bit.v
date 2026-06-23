module comparator_4bit (
    input  [3:0] A,        // First 4-bit input operand
    input  [3:0] B,        // Second 4-bit input operand
    output       A_greater, // High if A > B
    output       A_equal,   // High if A == B
    output       A_less     // High if A < B
);

    // Subtraction-based comparison: A - B
    // MSB of the 5-bit result indicates borrow (1 = borrow => A < B)
    wire [4:0] sub_result;
    assign sub_result = {1'b0, A} - {1'b0, B};

    assign A_less   = sub_result[4];                        // borrow occurred => A < B
    assign A_equal  = (sub_result[3:0] == 4'b0);           // zero diff => A == B
    assign A_greater = ~sub_result[4] & (|sub_result[3:0]); // no borrow & non-zero diff => A > B

endmodule
