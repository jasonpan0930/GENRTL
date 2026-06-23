// fixed_point_substractor
// Fixed-point subtractor using sign-magnitude representation
// Top-level ports per spec/design.spec.txt

module fixed_point_substractor #(
    parameter N = 16,  // Total number of bits (sign + integer + fractional)
    parameter Q = 8    // Number of fractional bits
) (
    input  [N-1:0] a,  // First N-bit fixed-point input operand
    input  [N-1:0] b,  // Second N-bit fixed-point input operand
    output [N-1:0] c   // N-bit output representing a - b
);

    wire sa, sb;
    wire [N-2:0] ma, mb;
    reg  [N-1:0] res;

    assign sa = a[N-1];
    assign sb = b[N-1];
    assign ma = a[N-2:0];
    assign mb = b[N-2:0];

    always @(*) begin
        if (sa == sb) begin
            // Same sign subtraction: subtract magnitudes
            if (ma >= mb) begin
                res[N-1]   = sa;
                res[N-2:0] = ma - mb;
            end else begin
                res[N-1]   = ~sa;  // sign flips when minuend < subtrahend
                res[N-2:0] = mb - ma;
            end
        end else begin
            // Different sign subtraction: add magnitudes
            // Result sign follows the operand with larger magnitude
            if ({1'b0, ma} >= {1'b0, mb}) begin
                res[N-1] = sa;
            end else begin
                res[N-1] = sb;
            end
            res[N-2:0] = ma + mb;
        end
    end

    // When result is zero, explicitly set sign bit to 0
    assign c = (res[N-2:0] == {(N-1){1'b0}}) ? {1'b0, {(N-1){1'b0}}} : res;

endmodule
