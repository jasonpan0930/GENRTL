module fixed_point_subtractor #(
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
    // Combinational fixed-point subtraction (a - b)
    // ============================================================
    assign same_sign = (a[N-1] == b[N-1]);
    assign abs_a = a[N-2:0];
    assign abs_b = b[N-2:0];

    always @(*) begin
        if (same_sign) begin
            // Same sign: subtract magnitudes, keep common sign
            if (abs_a >= abs_b) begin
                c = {a[N-1], (abs_a - abs_b)};
            end else begin
                c = {a[N-1], (abs_b - abs_a)};
            end
        end else begin
            // Different sign: add magnitudes
            c = {a[N-1], (abs_a + abs_b)};
        end
        // Handle zero result
        if (c[N-2:0] == {N-1{1'b0}}) begin
            c = {N{1'b0}};
        end
    end

endmodule
