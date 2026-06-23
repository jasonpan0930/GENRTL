// synchronizer
// Multi-bit MUX-based clock domain crossing synchronizer.
// clk_a domain: registers data_in and data_en.
// clk_b domain: 2-stage sync of enable, then muxes dataout.

module synchronizer (
    input        clk_a,    // clock A
    input        clk_b,    // clock B
    input        arstn,    // active-low async reset for clk_a domain
    input        brstn,    // active-low async reset for clk_b domain
    input  [3:0] data_in,  // 4-bit input data (clk_a domain)
    input        data_en,  // enable signal (clk_a domain)
    output [3:0] dataout   // synchronized output (clk_b domain)
);

    reg [3:0] data_reg;       // data register (clk_a domain)
    reg       en_data_reg;    // enable register (clk_a domain)

    reg       en_clap_one;    // first-stage sync (clk_b domain)
    reg       en_clap_two;    // second-stage sync (clk_b domain)

    reg [3:0] dataout_reg;    // output register (clk_b domain)

    // clk_a domain: data register
    always @(posedge clk_a or negedge arstn) begin
        if (!arstn)
            data_reg <= 4'd0;
        else
            data_reg <= data_in;
    end

    // clk_a domain: enable register
    always @(posedge clk_a or negedge arstn) begin
        if (!arstn)
            en_data_reg <= 1'b0;
        else
            en_data_reg <= data_en;
    end

    // clk_b domain: 2-stage enable synchronizer
    always @(posedge clk_b or negedge brstn) begin
        if (!brstn) begin
            en_clap_one <= 1'b0;
            en_clap_two <= 1'b0;
        end else begin
            en_clap_one <= en_data_reg;
            en_clap_two <= en_clap_one;
        end
    end

    // clk_b domain: output data register with enable
    always @(posedge clk_b or negedge brstn) begin
        if (!brstn)
            dataout_reg <= 4'd0;
        else if (en_clap_two)
            dataout_reg <= data_reg;
        // else hold previous value
    end

    assign dataout = dataout_reg;

endmodule
