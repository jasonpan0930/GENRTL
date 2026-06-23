// Mealy FSM detecting sequence "10011" on single-bit input IN
// MATCH is asserted in the same cycle as the final "1" of "10011"
// Supports overlapping sequences (e.g., 100110011 -> MATCH at 5th and 9th bits)
//
// SPEC ref: spec/design.spec.txt

module fsm (
    input  wire IN,    // FSM input signal
    input  wire CLK,   // Clock signal
    input  wire RST,   // Reset signal (active high, synchronous)
    output reg  MATCH  // Match output (1 when "10011" detected)
);

    // State encoding
    localparam S0 = 3'd0,  // idle / saw nothing
               S1 = 3'd1,  // saw "1"
               S2 = 3'd2,  // saw "10"
               S3 = 3'd3,  // saw "100"
               S4 = 3'd4;  // saw "1001"

    reg [2:0] state, next_state;

    // Sequential logic
    always @(posedge CLK) begin
        if (RST) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end

    // Next state and output logic (Mealy)
    always @(*) begin
        next_state = state;
        MATCH = 1'b0;

        case (state)
            S0: begin
                if (IN)       next_state = S1;
                else          next_state = S0;
            end
            S1: begin
                if (IN)       next_state = S1;
                else          next_state = S2;
            end
            S2: begin
                if (IN)       next_state = S1;
                else          next_state = S3;
            end
            S3: begin
                if (IN)       next_state = S4;
                else          next_state = S0;
            end
            S4: begin
                if (IN) begin
                    next_state = S1;  // overlapping: last "1" starts next match
                    MATCH = 1'b1;
                end else begin
                    next_state = S2;  // saw "10010" -> keep "10"
                end
            end
            default: begin
                next_state = S0;
            end
        endcase
    end

    // Registered output to avoid glitches
    // Per SPEC: MATCH at the same time as the last occurrence of IN=1
    // (Mealy output is already combinatorial, matching the same cycle)
    // We use the combinatorial MATCH from the always block above.

endmodule
