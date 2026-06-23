module accu (
    input  wire       clk,       // Clock input for synchronization
    input  wire       rst_n,     // Active-low reset signal
    input  wire [7:0] data_in,   // 8-bit input data for addition
    input  wire       valid_in,  // Input signal indicating readiness for new data
    output reg        valid_out, // Output signal indicating when 4 input data accumulation is reached
    output reg  [9:0] data_out   // 10-bit output data representing the accumulated sum
);

    // Counter for number of valid inputs received (0..3)
    reg [1:0] cnt;
    // Accumulator register
    reg [9:0] acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 2'd0;
            acc       <= 10'd0;
            valid_out <= 1'd0;
            data_out  <= 10'd0;
        end else begin
            // Default: valid_out pulses only for one cycle
            valid_out <= 1'd0;

            if (valid_in) begin
                if (cnt == 2'd3) begin
                    // Fourth valid input: output accumulated result
                    data_out  <= acc + data_in;
                    valid_out <= 1'd1;
                    cnt       <= 2'd0;
                    acc       <= 10'd0;
                end else begin
                    // Accumulate and increment counter
                    acc <= acc + data_in;
                    cnt <= cnt + 1'd1;
                end
            end
        end
    end

endmodule
