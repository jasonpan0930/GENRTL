// TopModule — review2015_fancytimer (VerilogEval #156)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input         clk,
    input         reset,
    input         data,
    output reg [3:0] count,
    output reg    counting,
    output reg    done,
    input         ack
);

    // FSM state encoding
    localparam S0    = 3'd0,
               S1    = 3'd1,
               S2    = 3'd2,
               S3    = 3'd3,
               SHIFT = 3'd4,
               COUNT = 3'd5,
               DONE  = 3'd6;

    // Stage 0 — State register
    reg [2:0] state;

    // Stage 0 — Delay shift register and counters
    reg [3:0] shift_sreg;
    reg [1:0] shift_cnt;
    reg [9:0] cycle_cnt;
    reg [3:0] delay_rem;

    // Stage 0 — Next-state combinational logic
    reg [2:0] nstate;

    always @(*) begin
        case (state)
            S0:     nstate = (data) ? S1 : S0;
            S1:     nstate = (data) ? S2 : S0;
            S2:     nstate = (data) ? S2 : S3;
            S3:     nstate = (data) ? SHIFT : S0;
            SHIFT:  nstate = (shift_cnt == 2'd3) ? COUNT : SHIFT;
            COUNT:  nstate = (cycle_cnt == 10'd999 && delay_rem == 4'd0) ? DONE : COUNT;
            DONE:   nstate = (ack) ? S0 : DONE;
            default: nstate = S0;
        endcase
    end

    // Stage 0 — Output decode (combinational)
    always @(*) begin
        counting = (state == COUNT);
        done     = (state == DONE);
    end

    // Stage 0 — Sequential updates
    always @(posedge clk) begin
        if (reset) begin
            state     <= S0;
            shift_sreg <= 4'd0;
            shift_cnt <= 2'd0;
            cycle_cnt <= 10'd0;
            delay_rem <= 4'd0;
            count     <= 4'd0;
        end else begin
            state <= nstate;

            // SHIFT: shift in delay bits MSB-first, track count
            if (state == SHIFT) begin
                shift_sreg <= {data, shift_sreg[3:1]};
                if (shift_cnt == 2'd3)
                    shift_cnt <= 2'd0;
                else
                    shift_cnt <= shift_cnt + 2'd1;
            end

            // SHIFT→COUNT transition: capture delay from shift_sreg
            // Use {data, shift_sreg[3:1]} directly so the 4th bit (data)
            // is combined with the 3 prior bits from shift_sreg (old value)
            if (state == SHIFT && nstate == COUNT) begin
                delay_rem <= {data, shift_sreg[3:1]};
                cycle_cnt <= 10'd0;
            end

            // COUNT: run cycle and delay counters, output count
            if (state == COUNT) begin
                count <= delay_rem;
                if (cycle_cnt == 10'd999) begin
                    cycle_cnt <= 10'd0;
                    if (delay_rem > 4'd0)
                        delay_rem <= delay_rem - 4'd1;
                end else begin
                    cycle_cnt <= cycle_cnt + 10'd1;
                end
            end
        end
    end

endmodule
