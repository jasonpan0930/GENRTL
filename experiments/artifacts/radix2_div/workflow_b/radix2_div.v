// radix2_div — 8-bit radix-2 divider with handshake
// Supports both signed and unsigned division
// FSM: IDLE → COMPUTE (8 cycles) → DONE

module radix2_div (
  input         clk,
  input         rst,
  input         sign,
  input  [7:0]  dividend,
  input  [7:0]  divisor,
  input         opn_valid,
  input         res_ready,
  output reg    res_valid,
  output reg [15:0] result
);

  // FSM states
  localparam IDLE    = 2'b00;
  localparam COMPUTE = 2'b01;
  localparam DONE    = 2'b10;
  reg [1:0] state;

  // Sampled inputs
  reg       sign_r;
  reg [7:0] abs_dividend_r;
  reg [7:0] abs_divisor_r;
  reg       dividend_neg;
  reg       divisor_neg;

  // Restoring division registers
  reg [7:0] A;          // accumulator (remainder)
  reg [7:0] Q;          // quotient
  reg [3:0] cnt;        // iteration counter (0..7 then done)

  // Combinational absolute values
  wire [7:0] abs_d   = (sign & dividend[7]) ? (~dividend + 1'b1) : dividend;
  wire [7:0] abs_div = (sign & divisor[7])  ? (~divisor  + 1'b1) : divisor;
  wire       d_neg   = sign & dividend[7];
  wire       div_neg = sign & divisor[7];

  // Combinational next state for restoring division
  // Use 9-bit subtraction to correctly detect borrow
  wire [7:0] A_sh  = {A[6:0], Q[7]};       // {A, Q} <<= 1
  wire [7:0] Q_sh  = {Q[6:0], 1'b0};
  wire [8:0] A_sub9 = {1'b0, A_sh} - {1'b0, abs_divisor_r};  // trial subtract (9-bit)
  wire       no_borrow = ~A_sub9[8];         // bit 8 = 0 means no borrow (A_sh >= divisor)
  wire [7:0] A_next = no_borrow ? A_sub9[7:0] : A_sh;
  wire [7:0] Q_next = {Q_sh[7:1], no_borrow};

  // FSM sequential
  always @(posedge clk) begin
    if (rst) begin
      state          <= IDLE;
      res_valid      <= 1'b0;
      result         <= 16'd0;
      A              <= 8'd0;
      Q              <= 8'd0;
      cnt            <= 4'd0;
      sign_r         <= 1'b0;
      abs_dividend_r <= 8'd0;
      abs_divisor_r  <= 8'd0;
      dividend_neg   <= 1'b0;
      divisor_neg    <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (opn_valid && !res_valid) begin
            sign_r         <= sign;
            abs_dividend_r <= abs_d;
            abs_divisor_r  <= abs_div;
            dividend_neg   <= d_neg;
            divisor_neg    <= div_neg;

            // Initialize A=0, Q=abs_dividend, cnt=0
            A     <= 8'd0;
            Q     <= abs_d;
            cnt   <= 4'd0;
            state <= COMPUTE;
          end
        end

        COMPUTE: begin
          // 8 iterations of restoring division (cnt = 0..7)
          A   <= A_next;
          Q   <= Q_next;

          if (cnt == 4'd7) begin
            // Division complete after this iteration
            reg [7:0] raw_q, raw_r;
            reg [7:0] final_q, final_r;

            // After loop: A=remainder, Q=quotient
            raw_q = Q_next;
            raw_r = A_next;

            // Apply signs
            if (sign_r) begin
              final_q = (dividend_neg ^ divisor_neg) ? (~raw_q + 1'b1) : raw_q;
              final_r = dividend_neg ? (~raw_r + 1'b1) : raw_r;
            end else begin
              final_q = raw_q;
              final_r = raw_r;
            end

            result    <= {final_r, final_q};
            res_valid <= 1'b1;
            cnt       <= 4'd0;
            state     <= DONE;
          end else begin
            cnt <= cnt + 4'd1;
          end
        end

        DONE: begin
          if (res_ready) begin
            res_valid <= 1'b0;
            state     <= IDLE;
          end
        end
      endcase
    end
  end

endmodule
