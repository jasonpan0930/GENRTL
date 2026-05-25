// adder_pipe_64bit — 64-bit pipelined ripple-carry adder (Workflow A)
// SPEC: spec/design.spec.txt

module adder_pipe_64bit (
    // SPEC: Input ports — clk
    input  wire        clk,
    // SPEC: Input ports — rst_n (active low)
    input  wire        rst_n,
    // SPEC: Input ports — i_en
    input  wire        i_en,
    // SPEC: Input ports — adda
    input  wire [63:0] adda,
    // SPEC: Input ports — addb
    input  wire [63:0] addb,
    // SPEC: Output ports — result (65-bit sum)
    output reg  [64:0] result,
    // SPEC: Output ports — o_en
    output reg         o_en
);

    // [ASSUMPTION] Four pipeline stages, 16 bits per stage (classic pipelined RCA).
    // [ASSUMPTION] rst_n deasserts synchronously; all registers clear when !rst_n.

    reg [63:0] op_a;
    reg [63:0] op_b;

    reg [15:0] sum15;
    reg [15:0] sum31;
    reg [15:0] sum47;
    reg [15:0] sum63;

    reg        carry16;
    reg        carry32;
    reg        carry48;
    reg        carry64;

    reg [2:0]  pipe_stage;
    reg [3:0]  i_en_pipe;

    wire [16:0] stage2_sum;
    wire [16:0] stage3_sum;
    wire [16:0] stage4_sum;
    wire [16:0] launch_sum;

    assign launch_sum = adda[15:0] + addb[15:0];
    assign stage2_sum = {1'b0, op_a[31:16]} + {1'b0, op_b[31:16]} + carry16;
    assign stage3_sum = {1'b0, op_a[47:32]} + {1'b0, op_b[47:32]} + carry32;
    assign stage4_sum = {1'b0, op_a[63:48]} + {1'b0, op_b[63:48]} + carry48;

    always @(posedge clk) begin
        if (!rst_n) begin
            op_a       <= 64'b0;
            op_b       <= 64'b0;
            sum15      <= 16'b0;
            sum31      <= 16'b0;
            sum47      <= 16'b0;
            sum63      <= 16'b0;
            carry16    <= 1'b0;
            carry32    <= 1'b0;
            carry48    <= 1'b0;
            carry64    <= 1'b0;
            pipe_stage <= 3'b0;
            i_en_pipe  <= 4'b0;
            result     <= 65'b0;
            o_en       <= 1'b0;
        end else begin
            o_en <= 1'b0;

            // SPEC: Implementation — synchronize i_en through pipeline stages
            i_en_pipe <= {i_en_pipe[2:0], i_en};

            if (i_en) begin
                op_a       <= adda;
                op_b       <= addb;
                sum15      <= launch_sum[15:0];
                carry16    <= launch_sum[16];
                pipe_stage <= 3'd1;
            end else begin
                case (pipe_stage)
                    3'd1: begin
                        sum31   <= stage2_sum[15:0];
                        carry32 <= stage2_sum[16];
                        pipe_stage <= 3'd2;
                    end
                    3'd2: begin
                        sum47   <= stage3_sum[15:0];
                        carry48 <= stage3_sum[16];
                        pipe_stage <= 3'd3;
                    end
                    3'd3: begin
                        sum63   <= stage4_sum[15:0];
                        carry64 <= stage4_sum[16];
                        pipe_stage <= 3'd4;
                    end
                    3'd4: begin
                        result <= {carry64, sum63, sum47, sum31, sum15};
                        // SPEC: Output ports — o_en (aligned with i_en_pipe depth)
                        o_en   <= 1'b1;
                        pipe_stage <= 3'b0;
                    end
                    default: ;
                endcase
            end
        end
    end

endmodule
