// 12-hour clock with BCD counters (hh=01-12, mm=00-59, ss=00-59)
module TopModule (
    input  clk,
    input  reset,
    input  ena,
    output reg pm,
    output reg [7:0] hh,  // two BCD digits {ten[3:0], one[3:0]}
    output reg [7:0] mm,
    output reg [7:0] ss
);

    wire [3:0] ss_ten = ss[7:4];
    wire [3:0] ss_one = ss[3:0];
    wire [3:0] mm_ten = mm[7:4];
    wire [3:0] mm_one = mm[3:0];
    wire [3:0] hh_ten = hh[7:4];
    wire [3:0] hh_one = hh[3:0];

    wire ss_wrap = (ss_ten == 4'd5 && ss_one == 4'd9);
    wire mm_wrap = (mm_ten == 4'd5 && mm_one == 4'd9);

    always @(posedge clk) begin
        if (reset) begin
            ss <= 8'h00;
            mm <= 8'h00;
            hh <= 8'h12;
            pm <= 1'b0;
        end else if (ena) begin
            // --- seconds BCD increment ---
            if (ss_one == 4'd9) begin
                if (ss_ten == 4'd5)
                    ss <= 8'h00;
                else
                    ss <= {ss_ten + 1'b1, 4'd0};
            end else begin
                ss <= {ss_ten, ss_one + 1'b1};
            end

            // --- minutes BCD increment (when seconds wrap) ---
            if (ss_wrap) begin
                if (mm_one == 4'd9) begin
                    if (mm_ten == 4'd5)
                        mm <= 8'h00;
                    else
                        mm <= {mm_ten + 1'b1, 4'd0};
                end else begin
                    mm <= {mm_ten, mm_one + 1'b1};
                end
            end

            // --- hours BCD increment (when minutes wrap) ---
            if (ss_wrap && mm_wrap) begin
                if (hh == 8'h12)
                    hh <= 8'h01;
                else if (hh_one == 4'd9)
                    hh <= {hh_ten + 1'b1, 4'd0};
                else
                    hh <= {hh_ten, hh_one + 1'b1};

                // toggle pm when going 11->12
                if (hh == 8'h11)
                    pm <= ~pm;
            end
        end
    end

endmodule
