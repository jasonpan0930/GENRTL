// fsm_serialdata (VerilogEval #146)
// TopModule: Serial byte receiver with data output (start+8data+stop, LSB first)
// All sequential on posedge clk, synchronous active-high reset

module TopModule (
    input        clk,
    input        reset,
    input        in,
    output [7:0] out_byte,
    output       done
);

    localparam IDLE   = 4'd0;
    localparam START  = 4'd1;
    localparam DATA_0 = 4'd2;
    localparam DATA_1 = 4'd3;
    localparam DATA_2 = 4'd4;
    localparam DATA_3 = 4'd5;
    localparam DATA_4 = 4'd6;
    localparam DATA_5 = 4'd7;
    localparam DATA_6 = 4'd8;
    localparam DATA_7 = 4'd9;
    localparam STOP   = 4'd10;
    localparam DONE   = 4'd11;
    localparam WAIT   = 4'd12;

    reg [3:0] state;
    reg [3:0] next_state;
    reg [7:0] data;

    wire shift_en;

    assign shift_en = (state >= START) && (state <= DATA_7);

    // Sequential
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            data  <= 8'd0;
        end else begin
            state <= next_state;
            if (shift_en)
                data <= {data[6:0], in};
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE:   next_state = in ? IDLE : START;
            START:  next_state = DATA_0;
            DATA_0: next_state = DATA_1;
            DATA_1: next_state = DATA_2;
            DATA_2: next_state = DATA_3;
            DATA_3: next_state = DATA_4;
            DATA_4: next_state = DATA_5;
            DATA_5: next_state = DATA_6;
            DATA_6: next_state = DATA_7;
            DATA_7: next_state = STOP;
            STOP:   next_state = in ? DONE : WAIT;
            DONE:   next_state = IDLE;
            WAIT:   next_state = in ? IDLE : WAIT;
            default: next_state = IDLE;
        endcase
    end

    // Outputs
    assign done     = (state == DONE);
    assign out_byte = data;

endmodule
