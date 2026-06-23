module multi_8bit (
    input  [7:0] A,      // First 8-bit input operand (multiplicand)
    input  [7:0] B,      // Second 8-bit input operand (multiplier)
    output [15:0] product // 16-bit product of A * B
);

    reg [15:0] product;
    integer i;

    always @(*) begin
        product = 16'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (B[i]) begin
                product = product + (A << i);
            end
        end
    end

endmodule
