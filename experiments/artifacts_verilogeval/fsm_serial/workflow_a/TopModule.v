module TopModule (
    input  clk,
    input  reset,
    input  in,
    output done
);

    // FSM states
    localparam IDLE       = 2'd0;
    localparam DATA       = 2'd1;
    localparam STOP_CHECK = 2'd2;
    localparam WAIT_STOP  = 2'd3;

    reg [1:0] state, next_state;
    reg [3:0] cnt;  // bit counter (0..7)

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic (combinational)
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (in == 1'b0)  // start bit detected
                    next_state = DATA;
            end
            DATA: begin
                if (cnt == 4'd7)  // all 8 data bits collected
                    next_state = STOP_CHECK;
            end
            STOP_CHECK: begin
                if (in == 1'b1)  // valid stop bit
                    next_state = IDLE;
                else              // stop bit error
                    next_state = WAIT_STOP;
            end
            WAIT_STOP: begin
                if (in == 1'b1)  // found next stop bit
                    next_state = IDLE;
            end
        endcase
    end

    // Bit counter
    always @(posedge clk) begin
        if (reset)
            cnt <= 4'd0;
        else if (state == DATA)
            cnt <= cnt + 1'b1;
        else
            cnt <= 4'd0;
    end

    // Done output — assert for one cycle on valid stop bit
    reg done_reg;
    always @(posedge clk) begin
        if (reset)
            done_reg <= 1'b0;
        else if (state == STOP_CHECK && in == 1'b1)
            done_reg <= 1'b1;
        else
            done_reg <= 1'b0;
    end
    assign done = done_reg;

endmodule
