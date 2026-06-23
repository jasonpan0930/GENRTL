module fixed_point_adder #(
    parameter Q = 4,
    parameter N = 8
) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output reg  [N-1:0] c
);

    // ============================================================
    // Internal declarations
    // ============================================================
    wire same_sign;
    wire [N-2:0] abs_a;
    wire [N-2:0] abs_b;

    // ============================================================
    // Combinational fixed-point addition
    // ============================================================
    assign same_sign = (a[N-1] == b[N-1]);
    assign abs_a = a[N-2:0];
    assign abs_b = b[N-2:0];

    always @(*) begin
        if (same_sign) begin
            // Same sign: add magnitudes, keep sign
            c = {a[N-1], (abs_a + abs_b)};
        end else begin
            // Different sign: subtract smaller from larger
            if (abs_a > abs_b) begin
                c = {1'b0, (abs_a - abs_b)};
            end else if (abs_b > abs_a) begin
                c = {1'b1, (abs_b - abs_a)};
            end else begin
                // Equal magnitudes → result is zero
                c = {N{1'b0}};
            end
        end
    end

endmodule
