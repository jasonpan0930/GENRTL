module synchronizer (
    input  wire       clk_a,
    input  wire       clk_b,
    input  wire       arstn,
    input  wire       brstn,
    input  wire [3:0] data_in,
    input  wire       data_en,
    output reg  [3:0] dataout
);

    // Internal signals
    reg [3:0] data_reg;
    reg       en_data_reg;
    reg       en_clap_one;
    reg       en_clap_two;

    // Stage 0: Domain A registers
    always @(posedge clk_a or negedge arstn) begin
        if (!arstn) begin
            data_reg    <= 4'd0;
            en_data_reg <= 1'b0;
        end else begin
            data_reg    <= data_in;
            en_data_reg <= data_en;
        end
    end

    // Stage 1: Enable synchronization (double-flop in domain B)
    always @(posedge clk_b or negedge brstn) begin
        if (!brstn) begin
            en_clap_one <= 1'b0;
            en_clap_two <= 1'b0;
        end else begin
            en_clap_one <= en_data_reg;
            en_clap_two <= en_clap_one;
        end
    end

    // Stage 2: Output data register (domain B)
    always @(posedge clk_b or negedge brstn) begin
        if (!brstn)
            dataout <= 4'd0;
        else if (en_clap_two)
            dataout <= data_reg;
    end

endmodule
