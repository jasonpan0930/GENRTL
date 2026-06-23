module multi_pipe_8bit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       mul_en_in,
    input  wire [7:0] mul_a,
    input  wire [7:0] mul_b,
    output reg        mul_en_out,
    output reg  [15:0] mul_out
);

    // ============================================================
    // Internal declarations
    // ============================================================
    // Stage 0: Input registers
    reg  [7:0] mul_a_reg;
    reg  [7:0] mul_b_reg;
    reg  [7:0] mul_en_shift;

    // Stage 1: Partial product wires
    wire [15:0] temp [0:7];

    // Stage 2: Pipeline sum registers
    reg  [15:0] sum [0:3];

    // Stage 3: Final accumulation register
    reg  [15:0] mul_out_reg;

    // ============================================================
    // Stage 0: Input sampling & enable shift
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_a_reg    <= 8'd0;
            mul_b_reg    <= 8'd0;
            mul_en_shift <= 8'd0;
        end else begin
            mul_en_shift <= {mul_en_shift[6:0], mul_en_in};
            if (mul_en_in) begin
                mul_a_reg <= mul_a;
                mul_b_reg <= mul_b;
            end
        end
    end

    // ============================================================
    // Stage 1: Partial product generation (combinational)
    // ============================================================
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_temp
            assign temp[i] = (mul_b_reg[i]) ? ({8'd0, mul_a_reg} << i) : 16'd0;
        end
    endgenerate

    // ============================================================
    // Stage 2: Pipeline sum registers (pairwise)
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        integer j;
        if (!rst_n) begin
            for (j = 0; j < 4; j = j + 1) begin
                sum[j] <= 16'd0;
            end
        end else begin
            sum[0] <= temp[0] + temp[1];
            sum[1] <= temp[2] + temp[3];
            sum[2] <= temp[4] + temp[5];
            sum[3] <= temp[6] + temp[7];
        end
    end

    // ============================================================
    // Stage 3: Final accumulation register
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out_reg <= 16'd0;
        end else begin
            mul_out_reg <= sum[0] + sum[1] + sum[2] + sum[3];
        end
    end

    // ============================================================
    // Stage 4: Output assignment (combinational)
    // ============================================================
    always @(*) begin
        mul_en_out = mul_en_shift[7];
        mul_out    = mul_en_shift[7] ? mul_out_reg : 16'd0;
    end

endmodule
