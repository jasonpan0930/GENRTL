// TopModule — fsm_serialdata (VerilogEval #146)
// Ref: spec_refined.md §3, timing_plan.md

module TopModule (
    input         clk,
    input         in,
    input         reset,
    output reg [7:0] out_byte,
    output reg    done
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
            out_byte <= 8'd0;
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
                    if (in) begin
                        done     <= 1'b1;
                        out_byte <= data_reg;
                    end
                end
                WAIT: begin
                    // wait for stop bit
                end
            endcase
        end
    end

endmodule
