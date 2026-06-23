// Module: adder_bcd
// 4-bit BCD adder for decimal arithmetic operations.
// Pure combinational; no clock or reset.
// Ref: spec_refined.md §2, timing_plan.md Stage0

module adder_bcd (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       Cin,
    output wire [3:0] Sum,
    output wire       Cout
);

    // Internal signals (declared before use, per domain_knowledge §1)
    wire [4:0] temp_sum;        // Binary sum of A + B + Cin (5-bit, range 0-19)
    wire       correction_en;   // High when temp_sum > 9
    wire [4:0] correction_val;  // 6 if correction_en, else 0
    wire [4:0] corrected_sum;   // temp_sum + correction_val

    // Stage 0: Binary addition (combinational)
    assign temp_sum = {1'b0, A} + {1'b0, B} + {4'd0, Cin};

    // Stage 0: Correction detection
    // temp_sum > 9  when bit 4 set OR (bit 3 AND bit 2) OR (bit 3 AND bit 1)
    assign correction_en = temp_sum[4]
                         | (temp_sum[3] & temp_sum[2])
                         | (temp_sum[3] & temp_sum[1]);

    // Stage 0: Correction value
    assign correction_val = correction_en ? 5'd6 : 5'd0;

    // Stage 0: Apply correction
    assign corrected_sum = temp_sum + correction_val;

    // Outputs
    assign Sum  = corrected_sum[3:0];
    assign Cout = correction_en;

endmodule
