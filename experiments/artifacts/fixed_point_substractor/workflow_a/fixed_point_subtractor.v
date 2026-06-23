// fixed_point_subtractor
// Fixed-point subtractor with sign-magnitude representation.
// Q: number of fractional bits
// N: total number of bits (including sign)
//
// Ports (SPEC sections):
//   a [N-1:0] — First N-bit fixed-point input operand
//   b [N-1:0] — Second N-bit fixed-point input operand
//   c [N-1:0] — N-bit result of fixed-point subtraction
//
// Uses sign-magnitude format: MSB = sign (0 positive, 1 negative),
// remaining N-1 bits = magnitude, with implied binary point at bit Q.

module fixed_point_subtractor #(
    parameter N = 16,
    parameter Q = 8
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    // Internal register for result storage
    reg [N-1:0] res;

    // Sign and magnitude extraction
    wire        sign_a;
    wire        sign_b;
    wire [N-1:0] mag_a;
    wire [N-1:0] mag_b;

    assign sign_a = a[N-1];
    assign sign_b = b[N-1];
    assign mag_a  = {1'b0, a[N-2:0]};  // zero-extend for overflow guard
    assign mag_b  = {1'b0, b[N-2:0]};

    reg [N-1:0] tmp;   // intermediate for arithmetic results

    always @(*) begin
        if (sign_a == sign_b) begin
            // Same Sign Subtraction (SPEC §Implementation):
            // Subtract magnitudes; result sign = sign of inputs when |a| >= |b|,
            // otherwise flipped.
            if (mag_a >= mag_b) begin
                tmp = mag_a - mag_b;
                res[N-1]   = sign_a;
            end else begin
                tmp = mag_b - mag_a;
                res[N-1]   = ~sign_a;
            end
        end else begin
            // Different Sign Subtraction (SPEC §Implementation):
            // Add absolute values; result sign follows the operand with larger
            // magnitude.
            tmp = mag_a + mag_b;
            if (mag_a >= mag_b) begin
                res[N-1]   = sign_a;
            end else begin
                res[N-1]   = sign_b;
            end
        end

        // Extract the N-1 magnitude bits from tmp and assign to result
        res[N-2:0] = tmp[N-2:0];

        // Handling Zero (SPEC §Implementation):
        // When the result is zero, force sign bit to 0.
        if (res[N-2:0] == {N-1{1'b0}}) begin
            res[N-1] = 1'b0;
        end
    end

    assign c = res;

endmodule
