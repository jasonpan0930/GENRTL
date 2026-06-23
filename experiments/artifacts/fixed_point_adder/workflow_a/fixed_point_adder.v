// fixed_point_adder: parameterized signed-magnitude fixed-point adder
//
// Spec: spec/design.spec.txt
// Parameters:
//   N - total bits (including sign + integer + fractional)
//   Q - number of fractional bits
//
// Ports (matching SPEC):
//   a[N-1:0] - first operand
//   b[N-1:0] - second operand
//   c[N-1:0] - sum output
//
// Representation: signed-magnitude
//   MSB (bit N-1) = sign (0 positive, 1 negative)
//   Bits N-2:0    = magnitude (absolute value)

module fixed_point_adder #(
    parameter Q = 8,
    parameter N = 16
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    // Internal result register (combinational)
    reg [N-1:0] res;

    // Sign and magnitude extraction
    wire       sign_a, sign_b;
    wire [N-2:0] mag_a, mag_b;

    assign sign_a = a[N-1];
    assign sign_b = b[N-1];
    assign mag_a  = a[N-2:0];
    assign mag_b  = b[N-2:0];

    always @(*) begin
        if (sign_a == sign_b) begin
            // Same sign: add magnitudes, keep common sign
            // Overflow wraps the magnitude bits internally
            res[N-2:0] = mag_a + mag_b;
            res[N-1]   = sign_a;
        end else begin
            // Different sign: subtract smaller magnitude from larger
            if (mag_a >= mag_b) begin
                // |a| >= |b|: result takes sign of a
                res = {sign_a, mag_a - mag_b};
            end else begin
                // |b| > |a|: result takes sign of b
                res = {sign_b, mag_b - mag_a};
            end
        end
    end

    assign c = res;

endmodule
