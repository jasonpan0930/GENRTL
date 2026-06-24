// PS/2 mouse protocol FSM — 3-byte message boundary detection

module TopModule (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] in,
    output reg        done
);

    localparam BYTE1 = 2'd0;
    localparam BYTE2 = 2'd1;
    localparam BYTE3 = 2'd2;

    reg [1:0] state;
    reg [1:0] next_state;

    // Next-state logic
    always @(*) begin
        case (state)
            BYTE1: next_state = in[3] ? BYTE2 : BYTE1;
            BYTE2: next_state = BYTE3;
            BYTE3: next_state = BYTE1;
            default: next_state = BYTE1;
        endcase
    end

    // State update and done output
    always @(posedge clk) begin
        if (reset) begin
            state <= BYTE1;
            done  <= 1'b0;
        end else begin
            state <= next_state;
            done  <= (state == BYTE3);
        end
    end

endmodule
