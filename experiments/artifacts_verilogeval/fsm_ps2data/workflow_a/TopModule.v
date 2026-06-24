// PS/2 data FSM: search for in[3]=1, then collect 3-byte message
module TopModule (
    input        clk,
    input        reset,
    input  [7:0] in,
    output reg [23:0] out_bytes,
    output reg done
);

    localparam SEARCH  = 2'd0;
    localparam BYTE2   = 2'd1;
    localparam BYTE3   = 2'd2;
    localparam FINISH  = 2'd3;

    reg [1:0] state, next_state;
    reg [7:0] byte1, byte2;

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= SEARCH;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            SEARCH: begin
                if (in[3])
                    next_state = BYTE2;
            end
            BYTE2:  next_state = BYTE3;
            BYTE3:  next_state = FINISH;
            FINISH: next_state = SEARCH;
        endcase
    end

    // Data path
    always @(posedge clk) begin
        if (reset) begin
            byte1 <= 8'd0;
            byte2 <= 8'd0;
            out_bytes <= 24'd0;
            done <= 1'b0;
        end else begin
            case (state)
                SEARCH: begin
                    if (in[3])
                        byte1 <= in;
                end
                BYTE2: begin
                    byte2 <= in;
                end
                BYTE3: begin
                    out_bytes <= {byte1, byte2, in};
                end
                FINISH: begin
                    done <= 1'b1;
                end
            endcase
            // Clear done after one cycle
            if (state != FINISH && next_state != FINISH)
                done <= 1'b0;
        end
    end

endmodule
