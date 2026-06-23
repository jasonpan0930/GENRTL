module div_16bit (
    input  [15:0] A,       // 16-bit dividend
    input  [7:0]  B,       // 8-bit divisor
    output [15:0] result,  // 16-bit quotient
    output [15:0] odd      // 16-bit remainder
);

    reg [15:0] a_reg;
    reg [7:0]  b_reg;
    reg [15:0] quotient;
    reg [15:0] remainder;

    // First combinational block: register inputs
    always @(*) begin
        a_reg = A;
        b_reg = B;
    end

    // Second combinational block: long-division algorithm
    always @(*) begin
        integer i;
        reg [15:0] temp_dividend;
        reg [15:0] temp_remainder;

        quotient = 16'd0;
        temp_dividend = a_reg;
        temp_remainder = 16'd0;

        for (i = 15; i >= 0; i = i - 1) begin
            temp_remainder = {temp_remainder[14:0], temp_dividend[15]};
            temp_dividend  = {temp_dividend[14:0], 1'b0};

            if (temp_remainder >= {8'b0, b_reg}) begin
                temp_remainder = temp_remainder - {8'b0, b_reg};
                quotient[i] = 1'b1;
            end
        end

        remainder = temp_remainder;
    end

    assign result = quotient;
    assign odd    = remainder;

endmodule
