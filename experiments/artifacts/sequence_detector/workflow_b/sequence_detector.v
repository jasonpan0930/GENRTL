//=============================================================================
// sequence_detector.v
//
// Sequence detector FSM: detects the 4-bit binary sequence 1001 (MSB-first)
// on the serial input data_in.  Output sequence_detected is asserted high
// for exactly one clock cycle when the full sequence is matched.
//
// Refined SPEC : spec_refined.md (§1, §2, §3, §4, §11)
// Timing plan  : timing_plan.md (§3.0 — Stage 0 combinational, §3.1 — Stage 1
//                sequential; §4 hierarchy: single module)
// Domain know  : domain_knowledge.en.md (§1 — declare before use)
//=============================================================================

module sequence_detector (
    input  wire       clk,                // System clock (positive edge)
    input  wire       rst_n,              // Active-low asynchronous reset
    input  wire       data_in,            // Serial bitstream input
    output wire       sequence_detected   // High for one cycle when 1001 detected
);

    //=========================================================================
    // State encoding (spec_refined §11)
    //=========================================================================
    localparam [2:0] IDLE = 3'b000;
    localparam [2:0] S1   = 3'b001;
    localparam [2:0] S2   = 3'b010;
    localparam [2:0] S3   = 3'b011;
    localparam [2:0] S4   = 3'b100;

    //=========================================================================
    // Internal declarations
    // Domain knowledge §1: declare all signals before any always/assign
    //=========================================================================
    reg  [2:0] state;                     // Stage 1 output: current FSM state
    reg  [2:0] next_state;                // Stage 0 output: next FSM state

    //=========================================================================
    // Stage 0 — Next-state logic (combinational)
    // timing_plan §3.0 | spec_refined §4.2
    //=========================================================================
    always @* begin
        case (state)
            IDLE:
                // data_in = 0: no start bit → stay IDLE
                // data_in = 1: first bit (1) matched → S1
                next_state = data_in ? S1 : IDLE;

            S1:
                // data_in = 0: second bit (0) matched → S2
                // data_in = 1: expected 0 but got 1; stay S1 (this 1 may
                //              start a new sequence)
                next_state = data_in ? S1 : S2;

            S2:
                // data_in = 0: third bit (0) matched → S3
                // data_in = 1: expected 0 but got 1; sequence broken → IDLE
                //              (per spec_refined §8 assumption)
                next_state = data_in ? IDLE : S3;

            S3:
                // data_in = 1: fourth bit (1) matched → S4
                // data_in = 0: expected 1 but got 0; no valid prefix → IDLE
                next_state = data_in ? S4 : IDLE;

            S4:
                // data_in = 0: overlap — trailing "10" of "...10010" is
                //              prefix of new sequence → S2
                // data_in = 1: overlap — trailing "1" of "...10011" starts
                //              new sequence → S1
                next_state = data_in ? S1 : S2;

            default:
                // Invalid / unreachable state encodings (3'b101, 3'b110,
                // 3'b111) → return to known state
                next_state = IDLE;
        endcase
    end

    //=========================================================================
    // Stage 0 — Output logic (combinational, Moore-type)
    // timing_plan §3.0 | spec_refined §4.2
    //
    // sequence_detected is asserted when state == S4.  Because state is a
    // registered output, this combinational decode behaves as a registered-
    // style output for timing purposes (timing_plan §7 item 3).
    //=========================================================================
    assign sequence_detected = (state == S4);

    //=========================================================================
    // Stage 1 — FSM state register (sequential)
    // timing_plan §3.1 | spec_refined §3
    //
    // Positive-edge clocked.  Asynchronous active-low reset forces state to
    // IDLE unconditionally.
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;              // Async reset (active-low)
        else
            state <= next_state;        // Normal operation
    end

endmodule
