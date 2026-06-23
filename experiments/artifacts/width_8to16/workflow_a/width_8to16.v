// width_8to16
// 8-bit to 16-bit width converter. First byte -> high, second byte -> low.

module width_8to16 (
    input        clk,       // clock
    input        rst_n,     // active-low async reset
    input        valid_in,  // input data valid
    input  [7:0] data_in,   // 8-bit input
    output       valid_out, // output data valid
    output [15:0] data_out  // 16-bit output
);

    reg        flag;        // 0 = waiting for first byte, 1 = waiting for second byte
    reg [7:0]  data_lock;   // stores first byte
    reg [15:0] data_out_reg;
    reg        valid_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flag           <= 1'b0;
            data_lock      <= 8'd0;
            data_out_reg   <= 16'd0;
            valid_out_reg  <= 1'b0;
        end else if (valid_in) begin
            if (flag) begin
                // Second byte: concatenate and output
                data_out_reg   <= {data_lock, data_in};
                valid_out_reg  <= 1'b1;
                flag           <= 1'b0;
            end else begin
                // First byte: store in high byte
                data_lock      <= data_in;
                valid_out_reg  <= 1'b0;
                flag           <= 1'b1;
            end
        end else begin
            valid_out_reg <= 1'b0;
        end
    end

    assign data_out  = data_out_reg;
    assign valid_out = valid_out_reg;

endmodule
