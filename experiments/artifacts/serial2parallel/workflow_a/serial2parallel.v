// serial2parallel
// 8-bit serial-to-parallel converter, MSB-first.
// Asserts dout_valid when 8 valid serial bits have been received.

module serial2parallel (
    input        clk,          // clock
    input        rst_n,        // active-low async reset
    input        din_serial,   // serial input (MSB first)
    input        din_valid,    // input data valid
    output [7:0] dout_parallel, // parallel output
    output       dout_valid    // output data valid
);

    reg [7:0] sreg;       // shift register
    reg [3:0] cnt;        // 4-bit bit counter (§Implementation)
    reg       dout_valid_reg;
    reg [7:0] dout_parallel_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt                <= 4'd0;
            sreg               <= 8'd0;
            dout_valid_reg     <= 1'b0;
            dout_parallel_reg  <= 8'd0;
        end else if (din_valid) begin
            if (cnt == 4'd7) begin
                // 8th bit received: output parallel data
                dout_parallel_reg <= {sreg[6:0], din_serial};
                dout_valid_reg    <= 1'b1;
                cnt               <= 4'd0;
                sreg              <= 8'd0;
            end else begin
                sreg   <= {sreg[6:0], din_serial};
                cnt    <= cnt + 1'd1;
                dout_valid_reg <= 1'b0;
            end
        end else begin
            dout_valid_reg <= 1'b0;
        end
    end

    assign dout_parallel = dout_parallel_reg;
    assign dout_valid    = dout_valid_reg;

endmodule
