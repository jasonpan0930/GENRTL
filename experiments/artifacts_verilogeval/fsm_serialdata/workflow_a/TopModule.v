// Serial protocol FSM with byte output (LSB-first, start=0, 8 data, stop=1)
module TopModule (
    input  clk,
    input  in,
    input  reset,
    output reg [7:0] out_byte,
    output reg done
);

    localparam IDLE       = 2'd0;
    localparam DATA       = 2'd1;
    localparam STOP_CHECK = 2'd2;
    localparam WAIT_STOP  = 2'd3;

    reg [1:0] state, next_state;
    reg [3:0] cnt;
    reg [7:0] shift_reg;

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (in == 1'b0)
                    next_state = DATA;
            end
            DATA: begin
                if (cnt == 4'd7)
                    next_state = STOP_CHECK;
            end
            STOP_CHECK: begin
                if (in == 1'b1)
                    next_state = IDLE;
                else
                    next_state = WAIT_STOP;
            end
            WAIT_STOP: begin
                if (in == 1'b1)
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

    // Shift register: capture data bits LSB-first
    always @(posedge clk) begin
        if (reset)
            shift_reg <= 8'd0;
        else if (state == DATA)
            shift_reg <= {in, shift_reg[7:1]};
    end

    // Outputs: out_byte and done
    always @(posedge clk) begin
        if (reset) begin
            out_byte <= 8'd0;
            done <= 1'b0;
        end else begin
            if (state == STOP_CHECK && in == 1'b1) begin
                out_byte <= shift_reg;
                done <= 1'b1;
            end else begin
                done <= 1'b0;
            end
        end
    end

endmodule
