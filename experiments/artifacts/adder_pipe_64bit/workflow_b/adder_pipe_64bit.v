//======================================================================
// adder_pipe_64bit — 64-bit pipelined ripple-carry adder
// 4 pipeline stages (STG_WIDTH=16), synchronous active-low reset.
// Latency: 4 clock cycles.
//======================================================================

module adder_pipe_64bit #(
    parameter DATA_WIDTH = 64,
    parameter STG_WIDTH  = 16
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             i_en,
    input  wire [DATA_WIDTH-1:0] adda,
    input  wire [DATA_WIDTH-1:0] addb,
    output wire [DATA_WIDTH:0]   result,
    output wire             o_en
);

    // Local parameter for number of stages
    localparam NUM_STAGES = DATA_WIDTH / STG_WIDTH;  // = 4

    // Internal signals (declared before use)
    // Pipeline registers
    reg [STG_WIDTH-1:0] sum_stg0;
    reg [STG_WIDTH-1:0] sum_stg1;
    reg [STG_WIDTH-1:0] sum_stg2;
    reg [STG_WIDTH-1:0] sum_stg3;
    reg                 carry_stg0;
    reg                 carry_stg1;
    reg                 carry_stg2;
    reg                 carry_stg3;
    reg                 en_stg0;
    reg                 en_stg1;
    reg                 en_stg2;
    reg                 en_stg3;

    // Stage 0: bits [15:0]
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stg0  <= {STG_WIDTH{1'b0}};
            carry_stg0 <= 1'b0;
            en_stg0   <= 1'b0;
        end else begin
            {carry_stg0, sum_stg0} <= adda[STG_WIDTH-1:0] + addb[STG_WIDTH-1:0];
            en_stg0 <= i_en;
        end
    end

    // Stage 1: bits [31:16]
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stg1  <= {STG_WIDTH{1'b0}};
            carry_stg1 <= 1'b0;
            en_stg1   <= 1'b0;
        end else begin
            {carry_stg1, sum_stg1} <= adda[2*STG_WIDTH-1:STG_WIDTH] +
                                      addb[2*STG_WIDTH-1:STG_WIDTH] +
                                      carry_stg0;
            en_stg1 <= en_stg0;
        end
    end

    // Stage 2: bits [47:32]
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stg2  <= {STG_WIDTH{1'b0}};
            carry_stg2 <= 1'b0;
            en_stg2   <= 1'b0;
        end else begin
            {carry_stg2, sum_stg2} <= adda[3*STG_WIDTH-1:2*STG_WIDTH] +
                                      addb[3*STG_WIDTH-1:2*STG_WIDTH] +
                                      carry_stg1;
            en_stg2 <= en_stg1;
        end
    end

    // Stage 3: bits [63:48]
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stg3  <= {STG_WIDTH{1'b0}};
            carry_stg3 <= 1'b0;
            en_stg3   <= 1'b0;
        end else begin
            {carry_stg3, sum_stg3} <= adda[4*STG_WIDTH-1:3*STG_WIDTH] +
                                      addb[4*STG_WIDTH-1:3*STG_WIDTH] +
                                      carry_stg2;
            en_stg3 <= en_stg2;
        end
    end

    // Output assignment
    assign result = {carry_stg3, sum_stg3, sum_stg2, sum_stg1, sum_stg0};
    assign o_en   = en_stg3;

endmodule
