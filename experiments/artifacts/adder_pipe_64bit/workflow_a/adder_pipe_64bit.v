/*
 * adder_pipe_64bit — 64-bit pipelined ripple-carry adder
 *
 * SPEC: spec/design.spec.txt
 *
 * Pipeline: 4 stages × 16 bits per stage.  The accumulated partial sum
 * (including inter-stage carries) is forwarded through the pipeline so
 * that after STAGES clock cycles the full 65-bit result is available.
 *
 * Ports:
 *   clk          — Clock input
 *   rst_n        — Active-low synchronous reset
 *   i_en         — Enable for the addition operation
 *   adda[63:0]   — 64-bit operand A
 *   addb[63:0]   — 64-bit operand B
 *   result[64:0] — 65-bit sum (including final carry)
 *   o_en         — Output valid (asserted when result is ready)
 */

module adder_pipe_64bit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       i_en,
    input  wire [63:0] adda,
    input  wire [63:0] addb,
    output reg  [64:0] result,
    output reg        o_en
);

    // ----------------------------------------------------------------
    // Configuration
    // ----------------------------------------------------------------
    localparam STAGES = 4;       // number of pipeline stages
    localparam BPP    = 16;      // bits computed per stage

    // ----------------------------------------------------------------
    // Pipeline registers
    // ----------------------------------------------------------------
    reg [63:0]      a_dly [0:STAGES-1];   // operand A at each stage
    reg [63:0]      b_dly [0:STAGES-1];   // operand B at each stage
    reg [STAGES-1:0] en_dly;              // enable signal through pipeline
    reg [64:0]       sum_dly [0:STAGES-1]; // accumulated result after each stage

    integer i, j;

    // ----------------------------------------------------------------
    // Stage logic — all registered (non-blocking assignments)
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1) begin
                a_dly[i]  <= 64'b0;
                b_dly[i]  <= 64'b0;
                en_dly[i] <= 1'b0;
                sum_dly[i] <= 65'b0;
            end
            result <= 65'b0;
            o_en   <= 1'b0;
        end else begin
            // ===== Stage 0: bits [BPP-1:0], carry_in = 0 =====
            en_dly[0] <= i_en;
            if (i_en) begin
                a_dly[0] <= adda;
                b_dly[0] <= addb;
            end

            begin
                reg [BPP:0] c;
                c[0] = 1'b0;
                for (j = 0; j < BPP; j = j + 1) begin
                    sum_dly[0][j] <= adda[j] ^ addb[j] ^ c[j];
                    c[j+1] = (adda[j] & addb[j])
                           | (adda[j] & c[j])
                           | (addb[j] & c[j]);
                end
                sum_dly[0][BPP] <= c[BPP];   // carry to stage 1
            end

            // ===== Stages 1 .. STAGES-1 =====
            for (i = 1; i < STAGES; i = i + 1) begin
                en_dly[i] <= en_dly[i-1];
                a_dly[i]  <= a_dly[i-1];
                b_dly[i]  <= b_dly[i-1];

                // Forward already-computed lower bits
                sum_dly[i] <= sum_dly[i-1];

                begin
                    reg [BPP:0] c;
                    // Carry from previous stage stored at position i*BPP
                    c[0] = sum_dly[i-1][i * BPP];
                    for (j = 0; j < BPP; j = j + 1) begin
                        sum_dly[i][i * BPP + j] <=
                            a_dly[i-1][i * BPP + j]
                          ^ b_dly[i-1][i * BPP + j]
                          ^ c[j];
                        c[j+1] = (a_dly[i-1][i * BPP + j]
                                  & b_dly[i-1][i * BPP + j])
                               | (a_dly[i-1][i * BPP + j] & c[j])
                               | (b_dly[i-1][i * BPP + j] & c[j]);
                    end
                    // Carry to next stage (final carry when i == STAGES-1)
                    sum_dly[i][i * BPP + BPP] <= c[BPP];
                end
            end

            // ===== Output =====
            result <= sum_dly[STAGES-1];
            o_en   <= en_dly[STAGES-1];
        end
    end

endmodule
