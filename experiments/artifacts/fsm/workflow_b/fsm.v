//======================================================================
// fsm
// Mealy FSM detecting sequence "10011" on single-bit input IN.
// MATCH is asserted (combinational) when the last bit '1' arrives.
// Supports overlapping detection.
// Reset: synchronous, active-high RST.
//======================================================================
module fsm (
    input  wire       CLK,
    input  wire       RST,
    input  wire       IN,
    output reg        MATCH
);

    //------------------------------------------------------------------
    // State encoding
    //------------------------------------------------------------------
    localparam IDLE = 3'b000,
               S1   = 3'b001,
               S2   = 3'b010,
               S3   = 3'b011,
               S4   = 3'b100;

    //------------------------------------------------------------------
    // Internal signals
    //------------------------------------------------------------------
    reg [2:0] state;
    reg [2:0] next_state;

    //------------------------------------------------------------------
    // Stage 0: State register (sequential)
    //------------------------------------------------------------------
    always @(posedge CLK) begin
        if (RST)
            state <= IDLE;
        else
            state <= next_state;
    end

    //------------------------------------------------------------------
    // Stage 1: Next-state and Mealy output logic (combinational)
    //------------------------------------------------------------------
    always @(*) begin
        next_state = IDLE;
        MATCH      = 1'b0;

        case (state)
            IDLE: begin
                if (IN) begin
                    next_state = S1;
                end else begin
                    next_state = IDLE;
                end
            end

            S1: begin
                if (IN) begin
                    next_state = S1;
                end else begin
                    next_state = S2;
                end
            end

            S2: begin
                if (IN) begin
                    next_state = S1;
                end else begin
                    next_state = S3;
                end
            end

            S3: begin
                if (IN) begin
                    next_state = S4;
                end else begin
                    next_state = IDLE;
                end
            end

            S4: begin
                if (IN) begin
                    next_state = S1;
                    MATCH      = 1'b1;       // "10011" detected
                end else begin
                    next_state = S2;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
