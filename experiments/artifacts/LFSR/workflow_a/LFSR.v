// LFSR — Linear Feedback Shift Register (4-bit)
// SPEC: spec/design.spec.txt — Memory/Shifter/LFSR
//
// Feedback polynomial: out[3] XOR out[2], inverted, fed into LSB on left shift.

module LFSR (
  output reg  [3:0] out,  // 4-bit LFSR state
  input  wire       clk,  // Clock
  input  wire       rst   // Active-high reset
);

  wire feedback;

  // feedback = ~(out[3] ^ out[2])
  assign feedback = ~(out[3] ^ out[2]);

  always @(posedge clk) begin
    if (rst) begin
      out <= 4'b0;
    end else begin
      out <= {out[2:0], feedback};
    end
  end

endmodule
