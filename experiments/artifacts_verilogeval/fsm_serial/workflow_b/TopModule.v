// TopModule — fsm_serial (VerilogEval #137)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input  clk,
    input  reset,
    input  in,
    output reg done
);

    // FSM state encoding
    localparam IDLE = 2'd0,
               DATA = 2'd1,
               STOP = 2'd2,
               WAIT = 2'd3;

    // Stage 0 — State, counter, shift register
    reg [1:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] data_reg;

    // Stage 0 — Next-state logic (combinational)
    reg [1:0] nstate;

    always @(*) begin
        case (state)
            IDLE:  nstate = (in) ? IDLE : DATA;
            DATA:  nstate = (bit_cnt == 3'd7) ? STOP : DATA;
            STOP:  nstate = (in) ? IDLE : WAIT;
            WAIT:  nstate = (in) ? IDLE : WAIT;
            default: nstate = IDLE;
        endcase
    end

    // Stage 0 — Sequential updates
    always @(posedge clk) begin
        if (reset) begin
            state    <= IDLE;
            bit_cnt  <= 3'd0;
            data_reg <= 8'd0;
            done     <= 1'b0;
        end else begin
            state <= nstate;
            done  <= 1'b0;

            case (state)
                IDLE: begin
                    bit_cnt <= 3'd0;
                end
                DATA: begin
                    data_reg <= {in, data_reg[7:1]};
                    bit_cnt <= bit_cnt + 3'd1;
                end
                STOP: begin
                    if (in)
                        done <= 1'b1;
                end
                WAIT: begin
                    // waiting
                end
            endcase
        end
    end

endmodule
