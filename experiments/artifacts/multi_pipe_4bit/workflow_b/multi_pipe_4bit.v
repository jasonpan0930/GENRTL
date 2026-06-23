// multi_pipe_4bit — 2-stage pipelined 4-bit unsigned multiplier
// Stage 0 (C): partial product generation
// Stage 1 (S): first-level sum
// Stage 2 (S): final sum

module multi_pipe_4bit (
  input         clk,
  input         rst_n,
  input  [3:0]  mul_a,
  input  [3:0]  mul_b,
  output reg [7:0] mul_out
);

  parameter size = 4;

  // Input extension (8-bit)
  wire [7:0] ext_a = {4'h0, mul_a};
  wire [7:0] ext_b = {4'h0, mul_b};

  // Partial products (generate block)
  wire [7:0] pp [0:size-1];
  genvar i;
  generate
    for (i = 0; i < size; i = i + 1) begin : pp_gen
      assign pp[i] = ext_b[i] ? (ext_a << i) : 8'h00;
    end
  endgenerate

  // Stage 1 registers: sum0 = pp[0]+pp[1], sum1 = pp[2]+pp[3]
  reg [7:0] sum0, sum1;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum0 <= 8'h00;
      sum1 <= 8'h00;
    end else begin
      sum0 <= pp[0] + pp[1];
      sum1 <= pp[2] + pp[3];
    end
  end

  // Stage 2 register: final product
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mul_out <= 8'h00;
    end else begin
      mul_out <= sum0 + sum1;
    end
  end

endmodule
