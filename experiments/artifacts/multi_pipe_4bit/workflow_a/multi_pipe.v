// Module: multi_pipe
// SPEC: spec/design.spec.txt — 4-bit unsigned pipeline multiplier (2 levels of registers)
//
// [ASSUMPTION] SPEC declares module name "multi_pipe_4bit" but run_context.json
// sets top_module to "multi_pipe". Using "multi_pipe" per test harness.
//
// Pipeline:
//   Stage 0 (combinational): extended inputs → partial products per generate block
//   Stage 1 (pipe registers): pp[0]+pp[1] → stage1_0, pp[2]+pp[3] → stage1_1
//   Stage 2 (output register): stage1_0 + stage1_1 → mul_out

module multi_pipe #(
    parameter size = 4
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [size-1:0]  mul_a,
    input  wire [size-1:0]  mul_b,
    output reg  [2*size-1:0] mul_out
);

    // ── Extended inputs (zero-pad "size" bits at MSB) ──
    wire [2*size-1:0] ext_a = {{size{1'b0}}, mul_a};
    wire [2*size-1:0] ext_b = {{size{1'b0}}, mul_b};

    // ── Partial products (combinational, generate block) ──
    wire [2*size-1:0] pp [0:size-1];

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_pp
            assign pp[i] = ext_b[i] ? (ext_a << i) : {2*size{1'b0}};
        end
    endgenerate

    // ── Pipeline stage 1 registers (intermediate sums) ──
    reg [2*size-1:0] stage1_0;
    reg [2*size-1:0] stage1_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_0 <= {2*size{1'b0}};
            stage1_1 <= {2*size{1'b0}};
        end else begin
            stage1_0 <= pp[0] + pp[1];
            stage1_1 <= pp[2] + pp[3];
        end
    end

    // ── Pipeline stage 2 output register (final product) ──
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_out <= {2*size{1'b0}};
        else
            mul_out <= stage1_0 + stage1_1;
    end

endmodule
