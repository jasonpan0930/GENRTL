// Conway's Game of Life — 16x16 toroidal grid, updated every cycle
module TopModule (
    input clk,
    input load,
    input [255:0] data,
    output reg [255:0] q
);

    wire [255:0] next_q;

    genvar r, c;
    generate
        for (r = 0; r < 16; r = r + 1) begin : row
            for (c = 0; c < 16; c = c + 1) begin : col
                // Pre-compute wrapped neighbor row/col indices
                localparam integer r_up   = (r == 0)    ? 15 : r - 1;
                localparam integer r_down = (r == 15)   ? 0  : r + 1;
                localparam integer c_left = (c == 0)    ? 15 : c - 1;
                localparam integer c_right= (c == 15)   ? 0  : c + 1;

                // 8 neighbor indices
                localparam [7:0] n0 = r_up   * 16 + c_left;
                localparam [7:0] n1 = r_up   * 16 + c;
                localparam [7:0] n2 = r_up   * 16 + c_right;
                localparam [7:0] n3 = r      * 16 + c_left;
                localparam [7:0] n4 = r      * 16 + c_right;
                localparam [7:0] n5 = r_down * 16 + c_left;
                localparam [7:0] n6 = r_down * 16 + c;
                localparam [7:0] n7 = r_down * 16 + c_right;

                wire [3:0] cnt = q[n0] + q[n1] + q[n2] + q[n3]
                               + q[n4] + q[n5] + q[n6] + q[n7];

                assign next_q[r * 16 + c] = (cnt == 3) ? 1'b1 :
                                             (cnt == 2) ? q[r * 16 + c] : 1'b0;
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (load)
            q <= data;
        else
            q <= next_q;
    end

endmodule
