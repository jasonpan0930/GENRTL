//==============================================================================
// float_multi — 32-bit IEEE-754 single-precision floating-point multiplier
// Workflow B pipeline (spec_refined → timing_plan → RTL)
// Problem #18 (RTLLM)
//==============================================================================
// Port order (must match testbench positional mapping): clk, rst, a, b, z
//==============================================================================

module float_multi (
  input  wire       clk,
  input  wire       rst,
  input  wire [31:0] a,
  input  wire [31:0] b,
  output reg  [31:0] z
);

  //============================================================================
  // Internal declarations
  //============================================================================

  // --- Counter ---
  reg  [2:0] counter;          // 3-bit cycle counter, 0..6

  // --- Input decode registers (Stage1) ---
  reg  [23:0] a_mantissa_reg;  // A mantissa with implicit leading 1
  reg  [23:0] b_mantissa_reg;  // B mantissa with implicit leading 1
  reg  [7:0]  a_exponent_reg;  // A raw exponent (biased)
  reg  [7:0]  b_exponent_reg;  // B raw exponent (biased)
  reg         a_sign_reg;      // A sign bit
  reg         b_sign_reg;      // B sign bit
  reg         a_zero_reg;      // A is zero
  reg         b_zero_reg;      // B is zero
  reg         a_nan_reg;       // A is NaN
  reg         b_nan_reg;       // B is NaN
  reg         a_inf_reg;       // A is infinity
  reg         b_inf_reg;       // B is infinity

  // --- Special-case registers (Stage2 result, stored in Stage3) ---
  reg         special_case_r;  // Special-case asserted
  reg         special_sign_r;  // Sign for special result
  reg  [7:0]  special_exp_r;   // Exponent for special result
  reg  [22:0] special_mant_r;  // Mantissa for special result

  // --- Multiply stage (Stage3) ---
  reg  [47:0] product;         // 48-bit mantissa product
  reg         z_sign_mult;     // Product sign
  reg  [7:0]  z_exp_mult;      // Product exponent (a_exp + b_exp - 127)

  // --- Normalization wires (Stage4, combinational) ---
  wire [23:0] norm_mantissa;
  wire [7:0]  norm_exponent;
  wire        guard_bit;
  wire        round_bit;
  wire        sticky;

  // --- Round/exp wires (Stage5, combinational) ---
  wire        z_sign_final;
  wire [7:0]  z_exp_final;
  wire [22:0] z_mant_final;

  //============================================================================
  // Counter (Stage0 / sequential)
  //============================================================================
  always @(posedge clk) begin
    if (rst) begin
      counter <= 3'd0;
    end else if (counter == 3'd6) begin
      counter <= 3'd0;
    end else begin
      counter <= counter + 3'd1;
    end
  end

  //============================================================================
  // Stage1 — Decode (sequential: sample inputs, extract fields)
  //============================================================================
  always @(posedge clk) begin
    if (rst) begin
      a_sign_reg     <= 1'd0;
      b_sign_reg     <= 1'd0;
      a_exponent_reg <= 8'd0;
      b_exponent_reg <= 8'd0;
      a_mantissa_reg <= 24'd0;
      b_mantissa_reg <= 24'd0;
      a_zero_reg     <= 1'd0;
      b_zero_reg     <= 1'd0;
      a_nan_reg      <= 1'd0;
      b_nan_reg      <= 1'd0;
      a_inf_reg      <= 1'd0;
      b_inf_reg      <= 1'd0;
    end else if (counter == 3'd1) begin
      a_sign_reg     <= a[31];
      b_sign_reg     <= b[31];
      a_exponent_reg <= a[30:23];
      b_exponent_reg <= b[30:23];
      a_mantissa_reg <= (a[30:23] == 8'd0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
      b_mantissa_reg <= (b[30:23] == 8'd0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
      a_zero_reg     <= (a[30:23] == 8'd0) && (a[22:0] == 23'd0);
      b_zero_reg     <= (b[30:23] == 8'd0) && (b[22:0] == 23'd0);
      a_nan_reg      <= (a[30:23] == 8'd255) && (a[22:0] != 23'd0);
      b_nan_reg      <= (b[30:23] == 8'd255) && (b[22:0] != 23'd0);
      a_inf_reg      <= (a[30:23] == 8'd255) && (a[22:0] == 23'd0);
      b_inf_reg      <= (b[30:23] == 8'd255) && (b[22:0] == 23'd0);
    end
  end

  //============================================================================
  // Stage2 — Special-case resolution (combinational)
  //============================================================================
  wire        special_case;
  wire        special_sign;
  wire [7:0]  special_exp;
  wire [22:0] special_mant;
  wire        z_sign_pre;
  wire [7:0]  z_exponent_pre;

  assign special_case = a_nan_reg | b_nan_reg | a_inf_reg | b_inf_reg |
                        a_zero_reg | b_zero_reg;
  assign z_sign_pre   = a_sign_reg ^ b_sign_reg;

  // NaN detected → canonical NaN (sign=0, exp=255, mant=0x400001)
  // Inf detected → Inf (sign=XOR, exp=255, mant=0)
  // Zero detected → Zero (sign=XOR, exp=0, mant=0)
  assign special_sign = z_sign_pre;
  assign special_exp  = (a_nan_reg | b_nan_reg) ? 8'd255 :
                        (a_inf_reg  | b_inf_reg) ? 8'd255 :
                        8'd0;
  assign special_mant = (a_nan_reg | b_nan_reg) ? 23'h400001 :
                        23'd0;

  // Normal path: precompute exponent sum for multiply stage
  // Combined biased exponent = a_exp + b_exp - 127
  assign z_exponent_pre = a_exponent_reg + b_exponent_reg - 8'd127;

  //============================================================================
  // Stage3 — Multiply (sequential)
  //============================================================================
  always @(posedge clk) begin
    if (rst) begin
      product        <= 48'd0;
      z_sign_mult    <= 1'd0;
      z_exp_mult     <= 8'd0;
      special_case_r <= 1'd0;
      special_sign_r <= 1'd0;
      special_exp_r  <= 8'd0;
      special_mant_r <= 23'd0;
    end else if (counter == 3'd2) begin
      // Capture special-case info for later use
      special_case_r <= special_case;
      special_sign_r <= special_sign;
      special_exp_r  <= special_exp;
      special_mant_r <= special_mant;

      if (special_case) begin
        product     <= 48'd0;
        z_sign_mult <= 1'd0;
        z_exp_mult  <= 8'd0;
      end else begin
        // Zero-extend both operands to 48 bits before multiply
        product     <= {24'd0, a_mantissa_reg} * {24'd0, b_mantissa_reg};
        z_sign_mult <= z_sign_pre;
        z_exp_mult  <= z_exponent_pre;
      end
    end
  end

  //============================================================================
  // Stage4 — Normalization (combinational)
  //============================================================================
  wire        temp_exp_adj;
  wire [23:0] raw_mantissa;
  wire [7:0]  raw_exponent;

  // product[47] determines shift
  assign temp_exp_adj = product[47] ? 1'd1 : 1'd0;

  assign raw_mantissa = product[47] ? product[47:24] : product[46:23];
  assign guard_bit    = product[47] ? product[23]    : product[22];
  assign round_bit    = product[47] ? product[22]    : product[21];
  assign sticky       = product[47] ? (|product[21:0]) : (|product[20:0]);

  assign raw_exponent = z_exp_mult + temp_exp_adj;

  //============================================================================
  // Stage5 — Rounding & exponent adjust (combinational)
  //============================================================================
  wire        round_up;
  wire [24:0] rounded_mantissa;
  wire [23:0] mantissa_after_round;
  wire [7:0]  exponent_after_round;
  wire        overflow;
  wire        underflow;
  reg         use_special;

  // Round-to-nearest-even
  assign round_up = guard_bit & (round_bit | sticky | raw_mantissa[0]);
  assign rounded_mantissa = {1'd0, raw_mantissa} + round_up;

  // Handle mantissa overflow from rounding (e.g., 0xFFFFFF + 1 = 0x1000000)
  assign mantissa_after_round = rounded_mantissa[24] ?
                                 rounded_mantissa[23:1] :
                                 rounded_mantissa[22:0];
  assign exponent_after_round = rounded_mantissa[24] ?
                                 raw_exponent + 8'd1 :
                                 raw_exponent;

  // Overflow: exponent >= 255 (biased)
  assign overflow  = (exponent_after_round >= 8'd255);
  // Underflow: exponent wraps (treated as 0)
  assign underflow = (exponent_after_round == 8'd0);

  assign z_exp_final  = overflow  ? 8'd255 :
                        underflow ? 8'd0   :
                        exponent_after_round;
  assign z_mant_final = overflow  ? 23'd0 :
                        underflow ? 23'd0 :
                        mantissa_after_round;
  assign z_sign_final = z_sign_mult;

  //============================================================================
  // Stage6 — Output register (sequential)
  //============================================================================
  always @(posedge clk) begin
    if (rst) begin
      z <= 32'd0;
    end else if (counter == 3'd6) begin
      if (special_case_r) begin
        z <= {special_sign_r, special_exp_r, special_mant_r};
      end else begin
        z <= {z_sign_final, z_exp_final, z_mant_final};
      end
    end
  end

endmodule
