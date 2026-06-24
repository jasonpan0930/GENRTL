// review2015_fancytimer (VerilogEval #156)
// TopModule: Fancy timer — detect 1101, shift 4, count (delay+1)*1000 cycles
// Synchronous active-high reset, posedge clk

module TopModule (
    input        clk,
    input        reset,
    input        data,
    output [3:0] count,
    output       counting,
    output       done,
    input        ack
);

    localparam S      = 4'd0;
    localparam S1     = 4'd1;
    localparam S11    = 4'd2;
    localparam S110   = 4'd3;
    localparam SHIFT0 = 4'd4;
    localparam SHIFT1 = 4'd5;
    localparam SHIFT2 = 4'd6;
    localparam SHIFT3 = 4'd7;
    localparam COUNT  = 4'd8;
    localparam DONE   = 4'd9;

    reg [3:0] state;
    reg [3:0] next_state;
    reg [3:0] delay_sr;
    reg [3:0] delay_rem;
    reg [9:0] cnt_1000;

    // Sequential
    always @(posedge clk) begin
        if (reset) begin
            state    <= S;
            delay_sr <= 4'd0;
            delay_rem <= 4'd0;
            cnt_1000 <= 10'd0;
        end else begin
            state <= next_state;

            // Shift register for delay bits
            if (state >= SHIFT0 && state <= SHIFT3)
                delay_sr <= {delay_sr[2:0], data};

            // Initialize delay_rem and cnt on entering COUNT
            if (state == SHIFT3) begin
                delay_rem <= delay_sr;
                cnt_1000  <= 10'd0;
            end else if (state == COUNT) begin
                if (cnt_1000 == 10'd999) begin
                    cnt_1000 <= 10'd0;
                    if (delay_rem != 4'd0)
                        delay_rem <= delay_rem - 4'd1;
                end else begin
                    cnt_1000 <= cnt_1000 + 10'd1;
                end
            end
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            S:      next_state = data ? S1 : S;
            S1:     next_state = data ? S11 : S;
            S11:    next_state = data ? S11 : S110;
            S110:   next_state = data ? SHIFT0 : S;
            SHIFT0: next_state = SHIFT1;
            SHIFT1: next_state = SHIFT2;
            SHIFT2: next_state = SHIFT3;
            SHIFT3: next_state = COUNT;
            COUNT:  next_state = (cnt_1000 == 10'd999 && delay_rem == 4'd0) ? DONE : COUNT;
            DONE:   next_state = ack ? S : DONE;
            default: next_state = S;
        endcase
    end

    // Output logic
    assign counting = (state == COUNT);
    assign done     = (state == DONE);
    assign count    = delay_rem;

endmodule
