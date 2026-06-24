// TopModule — HDLC bit-stuff detection FSM (Moore-type)
// Implements Prob140 from VerilogEval: recognizes 0111110 (disc),
// 01111110 (flag), and 7+ consecutive 1s (err).
//
// Stage 0: state register (sequential)
// Stage 1: next-state + output decode (combinational)

module TopModule (
  input  clk,
  input  reset,
  input  in,
  output disc,
  output flag,
  output err
);

  // ------------------------------------------------------------------
  // State encoding (from timing_plan.md §5)
  // ------------------------------------------------------------------
  localparam [3:0] IDLE  = 4'd0,
                   ONE   = 4'd1,
                   TWO   = 4'd2,
                   THREE = 4'd3,
                   FOUR  = 4'd4,
                   FIVE  = 4'd5,
                   SIX   = 4'd6,
                   DISC  = 4'd7,
                   FLAG  = 4'd8,
                   ERR   = 4'd9;

  // ------------------------------------------------------------------
  // Internal declarations (before always / assign — domain_knowledge §1)
  // ------------------------------------------------------------------
  reg [3:0] state;     // Stage 0: current state register
  reg [3:0] nstate;    // Stage 1: next state (combinational)

  // ------------------------------------------------------------------
  // Stage 0 — FSM state register (sequential)
  // ------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (reset)
      state <= IDLE;
    else
      state <= nstate;
  end

  // ------------------------------------------------------------------
  // Stage 1 — Next-state logic (combinational)
  // Full transition table from spec_refined.md §3.2
  // ------------------------------------------------------------------
  always_comb begin
    case (state)
      IDLE:  nstate = in ? ONE  : IDLE;
      ONE:   nstate = in ? TWO  : IDLE;
      TWO:   nstate = in ? THREE : IDLE;
      THREE: nstate = in ? FOUR  : IDLE;
      FOUR:  nstate = in ? FIVE  : IDLE;
      FIVE:  nstate = in ? SIX   : DISC;
      SIX:   nstate = in ? ERR   : FLAG;
      DISC:  nstate = in ? ONE   : IDLE;
      FLAG:  nstate = in ? ONE   : IDLE;
      ERR:   nstate = in ? ERR   : IDLE;
      default: nstate = IDLE;  // safe recovery for invalid state vectors
    endcase
  end

  // ------------------------------------------------------------------
  // Stage 1 — Output decode (Moore-type: function of current state only)
  // ------------------------------------------------------------------
  assign disc = (state == DISC);
  assign flag = (state == FLAG);
  assign err  = (state == ERR);

endmodule
