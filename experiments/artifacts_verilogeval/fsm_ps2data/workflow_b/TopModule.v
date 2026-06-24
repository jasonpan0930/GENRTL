// fsm_ps2data (VerilogEval #154)
// TopModule: PS/2 3-byte message FSM
// Synchronous active-high reset, posedge clk

module TopModule (
    input        clk,
    input        reset,
    input  [7:0] in,
    output [23:0] out_bytes,
    output       done
);

    localparam IDLE  = 2'd0;
    localparam BYTE2 = 2'd1;
    localparam BYTE3 = 2'd2;
    localparam DONE  = 2'd3;

    reg [1:0] state;
    reg [7:0] byte1;
    reg [7:0] byte2;
    reg [7:0] byte3;

    // Sequential
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            byte1 <= 8'd0;
            byte2 <= 8'd0;
            byte3 <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (in[3]) begin
                        byte1 <= in;
                        state <= BYTE2;
                    end
                end
                BYTE2: begin
                    byte2 <= in;
                    state <= BYTE3;
                end
                BYTE3: begin
                    byte3 <= in;
                    state <= DONE;
                end
                DONE: begin
                    byte1 <= in;
                    state <= BYTE2;
                end
            endcase
        end
    end

    // Outputs
    assign done      = (state == DONE);
    assign out_bytes = {byte1, byte2, byte3};

endmodule
