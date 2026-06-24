// TopModule — fsm_ps2data (VerilogEval #154)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input         clk,
    input         reset,
    input  [7:0]  in,
    output reg [23:0] out_bytes,
    output reg    done
);

    // FSM state encoding
    localparam IDLE  = 2'd0,
               BYTE2 = 2'd1,
               BYTE3 = 2'd2,
               DONE  = 2'd3;

    // Stage 0 — State register
    reg [1:0] state;

    // Stage 0 — Byte holding registers
    reg [7:0] byte1_reg;
    reg [7:0] byte2_reg;
    reg [7:0] byte3_reg;

    // Stage 0 — Next-state logic (combinational)
    reg [1:0] nstate;

    always @(*) begin
        case (state)
            IDLE: begin
                if (in[3])
                    nstate = BYTE2;
                else
                    nstate = IDLE;
            end
            BYTE2: begin
                nstate = BYTE3;
            end
            BYTE3: begin
                nstate = DONE;
            end
            DONE: begin
                if (in[3])
                    nstate = BYTE2;
                else
                    nstate = IDLE;
            end
            default: begin
                nstate = IDLE;
            end
        endcase
    end

    // Stage 0 — Sequential updates (state, byte regs, outputs)
    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            byte1_reg  <= 8'd0;
            byte2_reg  <= 8'd0;
            byte3_reg  <= 8'd0;
            out_bytes  <= 24'd0;
            done       <= 1'b0;
        end else begin
            state <= nstate;

            // Default values
            done <= 1'b0;

            case (state)
                IDLE: begin
                    if (in[3]) begin
                        byte1_reg <= in;
                    end
                end
                BYTE2: begin
                    byte2_reg <= in;
                end
                BYTE3: begin
                    byte3_reg <= in;
                end
                DONE: begin
                    out_bytes <= {byte1_reg, byte2_reg, byte3_reg};
                    done      <= 1'b1;
                    if (in[3]) begin
                        byte1_reg <= in;
                    end
                end
            endcase
        end
    end

endmodule
