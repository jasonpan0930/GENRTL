// multi_pipe_8bit — Unsigned 8-bit pipelined multiplier
// SPEC: spec/design.spec.txt
//
// Pipeline stages:
//   1. Input sampling (mul_a, mul_b) when mul_en_in is active
//   2. Partial product generation & group-wise summation
//   3. Final accumulation → mul_out_reg
//
// Latency: 3 cycles. mul_en_out is the MSB of a 3-bit shift register.

module multi_pipe_8bit (
    input         clk,          // Clock
    input         rst_n,        // Active-low reset, synchronous deassert
    input         mul_en_in,    // Input enable
    input  [7:0]  mul_a,        // Multiplicand (8-bit)
    input  [7:0]  mul_b,        // Multiplier (8-bit)
    output        mul_en_out,   // Output enable
    output [15:0] mul_out       // Product (16-bit)
);

    // ------------------------------------------------------------------
    // Pipeline registers
    // ------------------------------------------------------------------
    reg  [7:0]  mul_a_reg;       // Registered multiplicand
    reg  [7:0]  mul_b_reg;       // Registered multiplier
    reg  [2:0]  mul_en_out_reg;  // Enable shift register (3 deep)

    reg  [15:0] sum0, sum1;      // Stage-2 partial sums
    reg  [15:0] sum2, sum3;
    reg  [15:0] mul_out_reg;     // Final product register

    // ------------------------------------------------------------------
    // Wires: partial products (combinational)
    // ------------------------------------------------------------------
    wire [15:0] pp [0:7];        // 8 partial products, 16 bits each

    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin : gen_pp
            // pp[i] = mul_a_reg << i  when  mul_b_reg[i] == 1, else 0
            assign pp[i] = mul_b_reg[i] ? ({8'd0, mul_a_reg} << i) : 16'd0;
        end
    endgenerate

    // ------------------------------------------------------------------
    // Stage 1 — Input sampling (posedge clk, synchronous reset)
    // ------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_a_reg       <= 8'd0;
            mul_b_reg       <= 8'd0;
            mul_en_out_reg[0] <= 1'b0;
        end else begin
            if (mul_en_in) begin
                mul_a_reg <= mul_a;
                mul_b_reg <= mul_b;
            end
            mul_en_out_reg[0] <= mul_en_in;
        end
    end

    // ------------------------------------------------------------------
    // Stage 2 — Partial product summation (groups of 2)
    // ------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum0 <= 16'd0;
            sum1 <= 16'd0;
            sum2 <= 16'd0;
            sum3 <= 16'd0;
            mul_en_out_reg[1] <= 1'b0;
        end else begin
            sum0 <= pp[0] + pp[1];
            sum1 <= pp[2] + pp[3];
            sum2 <= pp[4] + pp[5];
            sum3 <= pp[6] + pp[7];
            mul_en_out_reg[1] <= mul_en_out_reg[0];
        end
    end

    // ------------------------------------------------------------------
    // Stage 3 — Final accumulation
    // ------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out_reg     <= 16'd0;
            mul_en_out_reg[2] <= 1'b0;
        end else begin
            mul_out_reg     <= sum0 + sum1 + sum2 + sum3;
            mul_en_out_reg[2] <= mul_en_out_reg[1];
        end
    end

    // ------------------------------------------------------------------
    // Output
    // ------------------------------------------------------------------
    // mul_en_out is the MSB of the 3-bit enable shift register
    assign mul_en_out = mul_en_out_reg[2];
    // mul_out = product when valid, otherwise 0
    assign mul_out    = mul_en_out ? mul_out_reg : 16'd0;

endmodule
