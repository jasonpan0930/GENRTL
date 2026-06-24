// conwaylife (VerilogEval #144)
// TopModule: Conway's Game of Life, 16x16 toroidal grid
// All sequential on posedge clk

module TopModule (
    input         clk,
    input         load,
    input  [255:0] data,
    output [255:0] q
);

    reg [255:0] q;

    // Next state computation
    reg [255:0] next_q;
    integer r, c, r_up, r_down, c_left, c_right;
    reg [3:0] nbr_sum;
    integer idx;

    always @(*) begin
        for (r = 0; r < 16; r = r + 1) begin
            r_up   = (r == 0)   ? 15 : r - 1;
            r_down = (r == 15)  ? 0  : r + 1;
            for (c = 0; c < 16; c = c + 1) begin
                c_left  = (c == 0)   ? 15 : c - 1;
                c_right = (c == 15)  ? 0  : c + 1;
                idx = r * 16 + c;

                nbr_sum = q[r_up   * 16 + c_left]  +
                          q[r_up   * 16 + c]        +
                          q[r_up   * 16 + c_right]  +
                          q[r      * 16 + c_left]   +
                          q[r      * 16 + c_right]  +
                          q[r_down * 16 + c_left]   +
                          q[r_down * 16 + c]        +
                          q[r_down * 16 + c_right];

                if (nbr_sum == 3)
                    next_q[idx] = 1'b1;
                else if (nbr_sum == 2)
                    next_q[idx] = q[idx];
                else
                    next_q[idx] = 1'b0;
            end
        end
    end

    // Sequential
    always @(posedge clk) begin
        if (load)
            q <= data;
        else
            q <= next_q;
    end

endmodule
