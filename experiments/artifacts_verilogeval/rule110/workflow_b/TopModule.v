// Rule 110 cellular automaton — 512 cells
// next = (~L & (C|R)) | (L & (C^R))

module TopModule (
    input  wire       clk,
    input  wire       load,
    input  wire [511:0] data,
    output reg  [511:0] q
);

    wire [511:0] q_next;
    genvar i;

    generate
        for (i = 0; i < 512; i = i + 1) begin : rule110_cell
            wire L = (i ==   0) ? 1'b0 : q[i-1];
            wire R = (i == 511) ? 1'b0 : q[i+1];
            assign q_next[i] = (~L & (q[i] | R)) | (L & (q[i] ^ R));
        end
    endgenerate

    always @(posedge clk) begin
        if (load)
            q <= data;
        else
            q <= q_next;
    end

endmodule
