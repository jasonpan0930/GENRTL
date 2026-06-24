// count_clock (VerilogEval #141)
// TopModule: 12-hour clock with AM/PM, BCD counters for hh/mm/ss
// All sequential logic on posedge clk, synchronous active-high reset

module TopModule (
    input  clk,
    input  reset,
    input  ena,
    output pm,
    output [7:0] hh,
    output [7:0] mm,
    output [7:0] ss
);

    // BCD digit registers
    reg [3:0] ss_ones;
    reg [3:0] ss_tens;
    reg [3:0] mm_ones;
    reg [3:0] mm_tens;
    reg [3:0] hh_ones;
    reg [3:0] hh_tens;
    reg pm_reg;

    // Next state values
    reg [3:0] ss_ones_nxt;
    reg [3:0] ss_tens_nxt;
    reg [3:0] mm_ones_nxt;
    reg [3:0] mm_tens_nxt;
    reg [3:0] hh_ones_nxt;
    reg [3:0] hh_tens_nxt;
    reg pm_nxt;

    // Intermediate carry signals
    wire ss_carry;
    wire mm_carry;
    wire is_12_59_59;

    assign ss_carry = ena && (ss_ones == 4'd9) && (ss_tens == 4'd5);
    assign mm_carry = ss_carry && (mm_ones == 4'd9) && (mm_tens == 4'd5);
    assign is_12_59_59 = mm_carry && (hh_tens == 4'd1) && (hh_ones == 4'd2);

    // Sequential block
    always @(posedge clk) begin
        if (reset) begin
            ss_ones <= 4'd0;
            ss_tens <= 4'd0;
            mm_ones <= 4'd0;
            mm_tens <= 4'd0;
            hh_ones <= 4'd2;
            hh_tens <= 4'd1;
            pm_reg  <= 1'd0;
        end else begin
            ss_ones <= ss_ones_nxt;
            ss_tens <= ss_tens_nxt;
            mm_ones <= mm_ones_nxt;
            mm_tens <= mm_tens_nxt;
            hh_ones <= hh_ones_nxt;
            hh_tens <= hh_tens_nxt;
            pm_reg  <= pm_nxt;
        end
    end

    // Seconds next logic
    always @(*) begin
        if (ena && ss_ones == 4'd9) begin
            ss_ones_nxt = 4'd0;
            ss_tens_nxt = (ss_tens == 4'd5) ? 4'd0 : (ss_tens + 4'd1);
        end else if (ena) begin
            ss_ones_nxt = ss_ones + 4'd1;
            ss_tens_nxt = ss_tens;
        end else begin
            ss_ones_nxt = ss_ones;
            ss_tens_nxt = ss_tens;
        end
    end

    // Minutes next logic
    always @(*) begin
        if (ss_carry && mm_ones == 4'd9) begin
            mm_ones_nxt = 4'd0;
            mm_tens_nxt = (mm_tens == 4'd5) ? 4'd0 : (mm_tens + 4'd1);
        end else if (ss_carry) begin
            mm_ones_nxt = mm_ones + 4'd1;
            mm_tens_nxt = mm_tens;
        end else begin
            mm_ones_nxt = mm_ones;
            mm_tens_nxt = mm_tens;
        end
    end

    // Hours next logic (12-hour BCD: 01-12)
    always @(*) begin
        if (mm_carry) begin
            if (is_12_59_59) begin
                // 12:59:59 -> 01:00:00
                hh_ones_nxt = 4'd1;
                hh_tens_nxt = 4'd0;
            end else if (hh_ones == 4'd9) begin
                // 09 -> 10
                hh_ones_nxt = 4'd0;
                hh_tens_nxt = hh_tens + 4'd1;
            end else begin
                // Normal increment
                hh_ones_nxt = hh_ones + 4'd1;
                hh_tens_nxt = hh_tens;
            end
        end else begin
            hh_ones_nxt = hh_ones;
            hh_tens_nxt = hh_tens;
        end
    end

    // PM next logic: toggle when 11:59:59 -> 12:00:00
    always @(*) begin
        if (mm_carry && (hh_tens == 4'd1) && (hh_ones == 4'd1))
            pm_nxt = ~pm_reg;
        else
            pm_nxt = pm_reg;
    end

    // Output assignments
    assign ss = {ss_tens, ss_ones};
    assign mm = {mm_tens, mm_ones};
    assign hh = {hh_tens, hh_ones};
    assign pm = pm_reg;

endmodule
