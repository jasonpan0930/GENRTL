//==============================================================================
// LFSR — 4-bit Linear Feedback Shift Register
//
// Feedback polynomial: ~(out[3] ^ out[2])
// Shift direction: left (MSB discarded, feedback inserted at LSB)
// Reset: synchronous active-HIGH, clears to 4'b0000
//==============================================================================

module LFSR (
  input        clk,   // System clock, positive edge
  input        rst,   // Synchronous active-HIGH reset
  output reg [3:0] out  // Current LFSR state
);

  //============================================================================
  // Internal declarations (signals declared before use)
  //============================================================================
  wire feedback;  // Combinational feedback value

  //============================================================================
  // Feedback logic — Stage 0 (Combinational)
  //============================================================================
  assign feedback = ~(out[3] ^ out[2]);

  //============================================================================
  // State register — Stage 1 (Sequential)
  //============================================================================
  always @(posedge clk) begin
    if (rst) begin
      out <= 4'b0000;  // Synchronous active-HIGH reset
    end else begin
      out <= {out[2:0], feedback};  // Shift left, insert feedback at LSB
    end
  end

endmodule
