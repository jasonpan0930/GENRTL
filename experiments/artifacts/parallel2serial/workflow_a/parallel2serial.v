// parallel2serial
// 4-bit parallel to serial converter, MSB first.
// valid_out = 1 when MSB is on dout; subsequent 3 bits output with valid_out = 0.

module parallel2serial (
    input        clk,       // clock
    input        rst_n,     // active-low async reset
    input  [3:0] d,         // 4-bit parallel input
    output       valid_out, // valid indicator for serial output
    output       dout       // serial output
);

    reg [3:0] data;   // data shift register
    reg [1:0] cnt;    // bit counter (0..3)
    reg       valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data  <= 4'd0;
            cnt   <= 2'd0;
            valid <= 1'b0;
        end else if (cnt == 2'd3) begin
            // Last bit of current word: load new parallel data, reset counter
            data  <= d;
            cnt   <= 2'd0;
            valid <= 1'b1;
        end else begin
            // Shift left (MSB->LSB rotation) and increment counter
            data  <= {data[2:0], data[3]};
            cnt   <= cnt + 1'd1;
            valid <= 1'b0;
        end
    end

    assign dout      = data[3];
    assign valid_out = valid;

endmodule
