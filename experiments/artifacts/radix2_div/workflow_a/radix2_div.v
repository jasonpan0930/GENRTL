// radix2_div - Simplified radix-2 divider for 8-bit signed/unsigned integers
// Based on SPEC: spec/design.spec.txt
//
// Ports:
//   clk        - Clock signal for synchronous operation
//   rst        - Reset signal (active-high, synchronous)
//   sign       - 1'b1 = signed operation, 1'b0 = unsigned operation
//   dividend   - 8-bit dividend
//   divisor    - 8-bit divisor
//   opn_valid  - Valid operation request
//   res_ready  - External circuit ready to accept result
//   res_valid  - Result valid and ready
//   result     - 16-bit output: {remainder[7:0], quotient[7:0]}

module radix2_div (
    input  wire       clk,
    input  wire       rst,
    input  wire       sign,
    input  wire [7:0] dividend,
    input  wire [7:0] divisor,
    input  wire       opn_valid,
    input  wire       res_ready,
    output reg        res_valid,
    output reg [15:0] result
);

    // ---------------------------------------------------------------
    // Internal registers
    // ---------------------------------------------------------------
    reg [15:0] SR;            // 16-bit shift register for radix-2 division
    reg [7:0]  NEG_DIVISOR;   // -abs(divisor) in two's complement
    reg [3:0]  cnt;           // Iteration counter (1 to 8)
    reg        start_cnt;     // Enable counting / division in progress
    reg        sign_q;        // Registered sign flag
    reg        dividend_neg_q;// Registered: was dividend negative?
    reg        divisor_neg_q; // Registered: was divisor negative?

    // ---------------------------------------------------------------
    // Combinational: subtraction result and carry-out
    //   sub_result = SR[15:8] + NEG_DIVISOR = SR[15:8] - abs(divisor)
    //   carry = 1  => no borrow (SR[15:8] >= abs(divisor))
    //   carry = 0  => borrow (SR[15:8] < abs(divisor))
    // ---------------------------------------------------------------
    wire [7:0] sub_result;
    wire       carry;
    assign {carry, sub_result} = SR[15:8] + NEG_DIVISOR;

    // ---------------------------------------------------------------
    // Sequential: main control and datapath
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            res_valid      <= 1'b0;
            result         <= 16'b0;
            SR             <= 16'b0;
            NEG_DIVISOR    <= 8'b0;
            cnt            <= 4'b0;
            start_cnt      <= 1'b0;
            sign_q         <= 1'b0;
            dividend_neg_q <= 1'b0;
            divisor_neg_q  <= 1'b0;
        end else begin
            // -------------------------------------------------------
            // Operation start: opn_valid high, res_valid low
            // -------------------------------------------------------
            if (opn_valid && !res_valid) begin
                sign_q         <= sign;
                dividend_neg_q <= sign & dividend[7];
                divisor_neg_q  <= sign & divisor[7];

                // SR = abs(dividend) << 1
                if (sign & dividend[7])
                    SR <= {8'b0, ~dividend + 8'b1} << 1;
                else
                    SR <= {8'b0, dividend} << 1;

                // NEG_DIVISOR = -abs(divisor)
                //   If divisor is negative: abs = ~divisor+1, so -abs = divisor
                //   If divisor is positive: -abs = -divisor = ~divisor+1
                if (sign & divisor[7])
                    NEG_DIVISOR <= divisor;
                else
                    NEG_DIVISOR <= ~divisor + 8'b1;

                cnt       <= 4'd1;
                start_cnt <= 1'b1;
                res_valid <= 1'b0;
            end
            // -------------------------------------------------------
            // Division process (start_cnt is high)
            // -------------------------------------------------------
            else if (start_cnt) begin
                if (cnt[3]) begin  // cnt == 8 (bit 3 set in 4-bit counter)
                    // Division complete
                    cnt       <= 4'b0;
                    start_cnt <= 1'b0;
                    res_valid <= 1'b1;

                    // Apply sign correction
                    //   quotient sign  = dividend_sign XOR divisor_sign
                    //   remainder sign = dividend_sign
                    if (sign_q & (dividend_neg_q ^ divisor_neg_q))
                        // Quotient needs negation
                        result <= {dividend_neg_q ? (~SR[15:8] + 8'b1) : SR[15:8],
                                   ~SR[7:0] + 8'b1};
                    else
                        result <= {dividend_neg_q ? (~SR[15:8] + 8'b1) : SR[15:8],
                                   SR[7:0]};
                end else begin
                    // Radix-2 division iteration
                    // carry=1: subtraction succeeded (SR[15:8] >= divisor)
                    //   -> quotient bit = 1, update working remainder
                    // carry=0: subtraction failed  (SR[15:8] < divisor)
                    //   -> quotient bit = 0, keep working remainder
                    if (carry)
                        SR <= {sub_result, SR[6:0], 1'b1};
                    else
                        SR <= {SR[14:8], SR[6:0], 1'b0};

                    cnt <= cnt + 4'b1;
                end
            end
            // -------------------------------------------------------
            // Result consumed: res_valid high and res_ready high
            // -------------------------------------------------------
            else if (res_valid && res_ready) begin
                res_valid <= 1'b0;
            end
        end
    end

endmodule
