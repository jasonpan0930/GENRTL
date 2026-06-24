// TopModule — count_clock (VerilogEval #141)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input        clk,
    input        reset,
    input        ena,
    output reg   pm,
    output reg [7:0] hh,
    output reg [7:0] mm,
    output reg [7:0] ss
);

    // Overflow flags (combinational)
    wire ss_overflow;
    wire mm_overflow;

    assign ss_overflow = ena && (ss == 8'h59);
    assign mm_overflow = ss_overflow && (mm == 8'h59);

    // Stage 0 — ss counter (Sequential)
    always @(posedge clk) begin
        if (reset) begin
            ss <= 8'h00;
        end else if (ena) begin
            if (ss[3:0] == 4'd9) begin
                ss[3:0] <= 4'd0;
                if (ss[7:4] == 4'd5)
                    ss[7:4] <= 4'd0;
                else
                    ss[7:4] <= ss[7:4] + 4'd1;
            end else begin
                ss[3:0] <= ss[3:0] + 4'd1;
            end
        end
    end

    // Stage 0 — mm counter (Sequential)
    always @(posedge clk) begin
        if (reset) begin
            mm <= 8'h00;
        end else if (ss_overflow) begin
            if (mm[3:0] == 4'd9) begin
                mm[3:0] <= 4'd0;
                if (mm[7:4] == 4'd5)
                    mm[7:4] <= 4'd0;
                else
                    mm[7:4] <= mm[7:4] + 4'd1;
            end else begin
                mm[3:0] <= mm[3:0] + 4'd1;
            end
        end
    end

    // Stage 0 — hh counter and pm (Sequential)
    always @(posedge clk) begin
        if (reset) begin
            hh <= 8'h12;
            pm <= 1'b0;
        end else if (mm_overflow) begin
            if (hh == 8'h12) begin
                hh <= 8'h01;
                pm <= ~pm;
            end else begin
                if (hh[3:0] == 4'd9) begin
                    hh[3:0] <= 4'd0;
                    hh[7:4] <= hh[7:4] + 4'd1;
                end else begin
                    hh[3:0] <= hh[3:0] + 4'd1;
                end
            end
        end
    end

endmodule
