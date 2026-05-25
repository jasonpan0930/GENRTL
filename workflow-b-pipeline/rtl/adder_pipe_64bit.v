// adder_pipe_64bit — Workflow B Agent3
// Hierarchy and stages per workflow-b-pipeline/timing_plan.md
// Ports and behavior per workflow-b-pipeline/spec_refined.md

module adder_pipe_64bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_en,
    input  wire [63:0] adda,
    input  wire [63:0] addb,
    output reg  [64:0] result,
    output reg         o_en
);

    // Operand and partial-sum pipeline (shifts every cycle — timing plan §4)
    reg [63:0] pipe_a0, pipe_a1, pipe_a2, pipe_a3;
    reg [63:0] pipe_b0, pipe_b1, pipe_b2, pipe_b3;
    reg [15:0] pipe_s0, pipe_s1, pipe_s2;
    reg        pipe_c0, pipe_c1, pipe_c2;

    // Enable shift chain — depth 4, spec §4 L=4 (timing plan §5)
    reg [3:0] en_pipe;

    // Stage 0 — segment [15:0] (timing plan Stage 0, Mixed)
    wire [16:0] tmp0 = pipe_a0[15:0] + pipe_b0[15:0];

    // Stage 1 — segment [31:16] (timing plan Stage 1)
    wire [16:0] tmp1 = pipe_a1[31:16] + pipe_b1[31:16] + pipe_c0;

    // Stage 2 — segment [47:32] (timing plan Stage 2)
    wire [16:0] tmp2 = pipe_a2[47:32] + pipe_b2[47:32] + pipe_c1;

    // Stage 3 — segment [63:48] and pack (timing plan Stage 3)
    wire [16:0] tmp3 = pipe_a3[63:48] + pipe_b3[63:48] + pipe_c2;
    wire [64:0] result_next = {tmp3[16], tmp3[15:0], pipe_s2, pipe_s1, pipe_s0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_a0  <= 64'b0;
            pipe_a1  <= 64'b0;
            pipe_a2  <= 64'b0;
            pipe_a3  <= 64'b0;
            pipe_b0  <= 64'b0;
            pipe_b1  <= 64'b0;
            pipe_b2  <= 64'b0;
            pipe_b3  <= 64'b0;
            pipe_s0  <= 16'b0;
            pipe_s1  <= 16'b0;
            pipe_s2  <= 16'b0;
            pipe_c0  <= 1'b0;
            pipe_c1  <= 1'b0;
            pipe_c2  <= 1'b0;
            en_pipe  <= 4'b0;
            result   <= 65'b0;
            o_en     <= 1'b0;
        end else begin
            // Enable pipeline — spec R10, timing plan enable chain
            en_pipe <= {en_pipe[2:0], i_en};
            o_en    <= en_pipe[3];

            // Stage 0 — capture operands when i_en (spec R3)
            if (i_en) begin
                pipe_a0 <= adda;
                pipe_b0 <= addb;
            end

            pipe_s0 <= tmp0[15:0];
            pipe_c0 <= tmp0[16];

            // Shift operands through stages (timing plan operand pass-through)
            pipe_a1 <= pipe_a0;
            pipe_b1 <= pipe_b0;
            pipe_s1 <= tmp1[15:0];
            pipe_c1 <= tmp1[16];

            pipe_a2 <= pipe_a1;
            pipe_b2 <= pipe_b1;
            pipe_s2 <= tmp2[15:0];
            pipe_c2 <= tmp2[16];

            pipe_a3 <= pipe_a2;
            pipe_b3 <= pipe_b2;

            // Output — 65-bit sum (spec R6), registered with o_en
            result <= result_next;
        end
    end

endmodule
