// Moore FSM detecting sequence 1101
// Sets start_shifting=1 permanently when sequence found

module TopModule (
    input  wire clk,
    input  wire reset,
    input  wire data,
    output reg  start_shifting
);

    localparam S0 = 3'd0;
    localparam S1 = 3'd1;
    localparam S2 = 3'd2;
    localparam S3 = 3'd3;
    localparam S4 = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    // Next-state logic
    always @(*) begin
        case (state)
            S0: next_state = data ? S1 : S0;
            S1: next_state = data ? S2 : S0;
            S2: next_state = data ? S2 : S3;
            S3: next_state = data ? S4 : S0;
            S4: next_state = S4;
            default: next_state = S0;
        endcase
    end

    // State update and sticky output
    always @(posedge clk) begin
        if (reset) begin
            state         <= S0;
            start_shifting <= 1'b0;
        end else begin
            state <= next_state;
            if (state == S3 && data)
                start_shifting <= 1'b1;
        end
    end

endmodule
