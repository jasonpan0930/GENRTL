module multi_pipe_4bit #(
    parameter size = 4
) (
    input wire clk,
    input wire rst_n,
    input wire [size-1:0] mul_a,
    input wire [size-1:0] mul_b,
    output reg [2*size-1:0] mul_out
);

    // Extend inputs by adding size zero bits at MSB positions
    wire [2*size-1:0] mul_a_ext;
    wire [2*size-1:0] mul_b_ext;

    assign mul_a_ext = {{size{1'b0}}, mul_a};
    assign mul_b_ext = {{size{1'b0}}, mul_b};

    // Partial products for each bit position of the multiplier
    wire [2*size-1:0] pp [0:size-1];

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_pp
            assign pp[i] = (mul_b_ext[i]) ? (mul_a_ext << i) : {2*size{1'b0}};
        end
    endgenerate

    // Two levels of registers for intermediate sums
    reg [2*size-1:0] sum_reg0;
    reg [2*size-1:0] sum_reg1;

    // Level 1: sum partial products in pairs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg0 <= {2*size{1'b0}};
            sum_reg1 <= {2*size{1'b0}};
        end else begin
            sum_reg0 <= pp[0] + pp[1];
            sum_reg1 <= pp[2] + pp[3];
        end
    end

    // Level 2: final product from sum of registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out <= {2*size{1'b0}};
        end else begin
            mul_out <= sum_reg0 + sum_reg1;
        end
    end

endmodule
