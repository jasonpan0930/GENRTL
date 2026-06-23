// Module: float_multi
// 32-bit floating-point multiplier (IEEE-754 single-precision)
// Reference: SPEC section "Implementation"
//   - Input Processing, Special Cases, Normalization,
//     Multiplication, Rounding, Output Generation

module float_multi (
    input         clk,    // Clock signal for synchronization
    input         rst,    // Reset signal (active high)
    input  [31:0] a,      // First operand in IEEE 754 format
    input  [31:0] b,      // Second operand in IEEE 754 format
    output reg [31:0] z    // Result of the multiplication in IEEE 754 format
);

    // Cycle counter for operation sequencing
    reg [2:0] counter;

    // Sign, exponent, mantissa storage
    reg        a_sign, b_sign, z_sign;
    reg [9:0]  a_exponent, b_exponent, z_exponent;
    reg [23:0] a_mantissa, b_mantissa, z_mantissa;

    // Intermediate product of the mantissas
    reg [49:0] product;

    // Rounding control bits
    reg guard_bit, round_bit, sticky;

    // IEEE-754 field extraction
    wire [7:0] raw_exp_a = a[30:23];
    wire [7:0] raw_exp_b = b[30:23];
    wire [22:0] raw_man_a = a[22:0];
    wire [22:0] raw_man_b = b[22:0];

    // Special case detection
    wire a_is_nan    = (raw_exp_a == 8'hFF) && (raw_man_a != 23'd0);
    wire b_is_nan    = (raw_exp_b == 8'hFF) && (raw_man_b != 23'd0);
    wire a_is_inf    = (raw_exp_a == 8'hFF) && (raw_man_a == 23'd0);
    wire b_is_inf    = (raw_exp_b == 8'hFF) && (raw_man_b == 23'd0);
    wire a_is_zero   = (raw_exp_a == 8'h00) && (raw_man_a == 23'd0);
    wire b_is_zero   = (raw_exp_b == 8'h00) && (raw_man_b == 23'd0);
    wire a_is_denorm = (raw_exp_a == 8'h00) && (raw_man_a != 23'd0);
    wire b_is_denorm = (raw_exp_b == 8'h00) && (raw_man_b != 23'd0);

    // Count leading zeros for denormal normalization
    reg [4:0] clz_a, clz_b;
    integer i;

    always @(*) begin
        // CLZ for a_mantissa (only used when a is denormal)
        clz_a = 0;
        if (a_is_denorm) begin
            for (i = 22; i >= 0; i = i - 1) begin
                if (!raw_man_a[i]) clz_a = clz_a + 1;
                else i = -1; // break
            end
        end
        // CLZ for b_mantissa
        clz_b = 0;
        if (b_is_denorm) begin
            for (i = 22; i >= 0; i = i - 1) begin
                if (!raw_man_b[i]) clz_b = clz_b + 1;
                else i = -1;
            end
        end
    end

    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialization: counter reset to zero
            counter     <= 3'd0;
            z           <= 32'd0;
            z_sign      <= 1'b0;
            z_exponent  <= 10'd0;
            z_mantissa  <= 24'd0;
            product     <= 50'd0;
            guard_bit   <= 1'b0;
            round_bit   <= 1'b0;
            sticky      <= 1'b0;
        end else begin
            case (counter)
                //--------------------------------------------------------------
                // Cycle 0: Input Processing & Special-Case Handling
                //--------------------------------------------------------------
                3'd0: begin
                    // Extract sign bits
                    a_sign <= a[31];
                    b_sign <= b[31];
                    z_sign <= a[31] ^ b[31];

                    // Special-case: NaN
                    if (a_is_nan || b_is_nan) begin
                        // Canonical NaN (quiet NaN with MSB of mantissa set)
                        z       <= {1'b0, 8'hFF, 23'h400000};
                        counter <= 3'd0;
                    end
                    // Special-case: infinity * 0  or  0 * infinity  => NaN
                    else if ((a_is_zero && b_is_inf) || (a_is_inf && b_is_zero)) begin
                        z       <= {1'b0, 8'hFF, 23'h400000};
                        counter <= 3'd0;
                    end
                    // Special-case: zero
                    else if (a_is_zero || b_is_zero) begin
                        z       <= {a[31] ^ b[31], 31'd0};
                        counter <= 3'd0;
                    end
                    // Special-case: infinity
                    else if (a_is_inf || b_is_inf) begin
                        z       <= {a[31] ^ b[31], 8'hFF, 23'd0};
                        counter <= 3'd0;
                    end
                    // Normal / denormal processing
                    else begin
                        // Load mantissas with implied bit
                        if (a_is_denorm) begin
                            // Denormal: implied bit is 0; normalize by shifting
                            // [ASSUMPTION] We normalize denormals to the leading 1 position
                            a_mantissa <= {1'b0, raw_man_a} << (clz_a + 1);
                        end else begin
                            a_mantissa <= {1'b1, raw_man_a};
                        end

                        if (b_is_denorm) begin
                            b_mantissa <= {1'b0, raw_man_b} << (clz_b + 1);
                        end else begin
                            b_mantissa <= {1'b1, raw_man_b};
                        end

                        // Load exponents (zero-extended to 10 bits)
                        if (a_is_denorm) begin
                            // Denormal exponent = 1 - bias (i.e. -126), represented as 1
                            a_exponent <= 10'd1;
                        end else begin
                            a_exponent <= {2'b0, raw_exp_a};
                        end

                        if (b_is_denorm) begin
                            b_exponent <= 10'd1;
                        end else begin
                            b_exponent <= {2'b0, raw_exp_b};
                        end

                        counter <= 3'd1;
                    end
                end

                //--------------------------------------------------------------
                // Cycle 1: Multiplication
                //   - Multiply 24-bit mantissas -> 48-bit product
                //   - Add exponents with bias subtraction
                //--------------------------------------------------------------
                3'd1: begin
                    // Mantissa multiplication
                    product    <= a_mantissa * b_mantissa;

                    // Exponent: E_a + E_b - bias (127)
                    // Use 10-bit arithmetic to detect overflow/underflow
                    z_exponent <= a_exponent + b_exponent - 10'd127;

                    counter    <= 3'd2;
                end

                //--------------------------------------------------------------
                // Cycle 2: Normalization & Rounding-bit collection
                //--------------------------------------------------------------
                3'd2: begin
                    if (product[47]) begin
                        // Product is >= 2.0, shift mantissa right by 1
                        // Fraction bits from [46:24] (23 bits) + implied 1 = product[47:24]
                        z_mantissa <= product[47:24];
                        guard_bit  <= product[23];
                        round_bit  <= product[22];
                        sticky     <= |product[21:0];
                        // Exponent adjustment for right-shift
                        z_exponent <= z_exponent + 1;
                    end else begin
                        // Product is >= 1.0 and < 2.0
                        z_mantissa <= product[46:23];
                        guard_bit  <= product[22];
                        round_bit  <= product[21];
                        sticky     <= |product[20:0];
                    end
                    counter <= 3'd3;
                end

                //--------------------------------------------------------------
                // Cycle 3: Rounding (round-to-nearest-even)
                //--------------------------------------------------------------
                3'd3: begin
                    // Round-to-nearest-even: (guard=1) AND (round OR sticky OR LSB=1)
                    if (guard_bit && (round_bit || sticky || z_mantissa[0])) begin
                        z_mantissa <= z_mantissa + 1;
                    end
                    counter <= 3'd4;
                end

                //--------------------------------------------------------------
                // Cycle 4: Post-rounding fixup & Output Generation
                //--------------------------------------------------------------
                3'd4: begin
                    // Handle rounding overflow (mantissa wrapped past 24'hFFFFFF)
                    if (&z_mantissa[23:0]) begin
                        // Mantissa overflowed, shift right
                        z_mantissa <= {1'b1, 23'd0};
                        z_exponent <= z_exponent + 1;
                    end

                    // Overflow check: exponent >= 0xFF
                    if (z_exponent >= 10'd255) begin
                        z <= {z_sign, 8'hFF, 23'd0};   // Infinity
                    end
                    // Underflow check: exponent <= 0
                    else if (z_exponent[9] || (z_exponent == 10'd0)) begin
                        // Treat underflow as zero / denormal
                        // [ASSUMPTION] Underflow flushes to zero
                        z <= {z_sign, 31'd0};
                    end
                    else begin
                        // Compose final IEEE-754 result
                        z <= {z_sign, z_exponent[7:0], z_mantissa[22:0]};
                    end

                    counter <= 3'd0;
                end

                default: counter <= 3'd0;
            endcase
        end
    end

endmodule
