// TopModule: PS/2 mouse message boundary detector
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk   - clock (positive edge)
//   reset - synchronous active-high reset
//   in[7:0] - input byte stream
//   done  - asserted for one cycle after third byte of each message

module TopModule (
    input        clk,
    input        reset,
    input  [7:0] in,
    output reg   done
);

    reg [1:0] state;

    localparam IDLE = 2'd0,
               S1   = 2'd1,
               S2   = 2'd2,
               S3   = 2'd3;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done  <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    if (in[3])
                        state <= S1;
                end
                S1:   state <= S2;
                S2:   state <= S3;
                S3: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
