// sequence_detector
// FSM-based sequence detector for 4-bit pattern "1001".
// Overlap allowed.

module sequence_detector (
    input  clk,       // clock
    input  rst_n,     // active-low async reset
    input  data_in,   // serial bit input
    output sequence_detected  // high when "1001" detected
);

    reg [2:0] state;
    reg       detected_reg;

    localparam IDLE = 3'd0,
               S1   = 3'd1,
               S2   = 3'd2,
               S3   = 3'd3,
               S4   = 3'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            detected_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    detected_reg <= 1'b0;
                    if (data_in)
                        state <= S1;
                    else
                        state <= IDLE;
                end
                S1: begin
                    detected_reg <= 1'b0;
                    if (data_in)
                        state <= S1;   // still waiting for 0
                    else
                        state <= S2;   // got "10"
                end
                S2: begin
                    detected_reg <= 1'b0;
                    if (data_in)
                        state <= S1;   // got "101", restart
                    else
                        state <= S3;   // got "100"
                end
                S3: begin
                    detected_reg <= 1'b0;
                    if (data_in)
                        state <= S4;   // got "1001"
                    else
                        state <= IDLE; // got "1000", no match
                end
                S4: begin
                    detected_reg <= 1'b1;  // sequence detected
                    if (data_in)
                        state <= S1;   // overlap: trailing "1"
                    else
                        state <= S2;   // overlap: trailing "10"
                end
                default: begin
                    state        <= IDLE;
                    detected_reg <= 1'b0;
                end
            endcase
        end
    end

    assign sequence_detected = detected_reg;

endmodule
