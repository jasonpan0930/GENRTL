// TopModule: sequence detector FSM for "1101"
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk           - clock (positive edge)
//   reset         - synchronous active-high reset
//   data          - serial input bit stream
//   start_shifting - asserted forever once "1101" is detected

module TopModule (
    input clk,
    input reset,
    input data,
    output reg start_shifting
);

    reg [2:0] state;

    localparam S0 = 3'd0,  // waiting for '1'
               S1 = 3'd1,  // received "1"
               S2 = 3'd2,  // received "11"
               S3 = 3'd3,  // received "110"
               S4 = 3'd4;  // received "1101" — done

    always @(posedge clk) begin
        if (reset) begin
            state         <= S0;
            start_shifting <= 1'b0;
        end else if (state == S4) begin
            // stay locked once detected
            start_shifting <= 1'b1;
        end else begin
            case (state)
                S0: if (data)      state <= S1;
                S1: if (data)      state <= S2;
                    else           state <= S0;
                S2: if (~data)     state <= S3;
                    else           state <= S2;  // overlapping "11"
                S3: if (data)      state <= S4;
                    else           state <= S0;
                default:           state <= S0;
            endcase
            start_shifting <= 1'b0;
        end
    end

endmodule
