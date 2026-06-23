module freq_div (
    input  wire CLK_in,
    input  wire RST,
    output reg  CLK_50,
    output reg  CLK_10,
    output reg  CLK_1
);

    // Internal signals
    reg [2:0] cnt_10;
    reg [5:0] cnt_100;

    // Stage 0: CLK_50 (/2)
    always @(posedge CLK_in or posedge RST) begin
        if (RST)
            CLK_50 <= 1'b0;
        else
            CLK_50 <= ~CLK_50;
    end

    // Stage 1: CLK_10 (/10)
    always @(posedge CLK_in or posedge RST) begin
        if (RST) begin
            CLK_10 <= 1'b0;
            cnt_10 <= 3'd0;
        end else if (cnt_10 == 3'd4) begin
            CLK_10 <= ~CLK_10;
            cnt_10 <= 3'd0;
        end else begin
            cnt_10 <= cnt_10 + 3'd1;
        end
    end

    // Stage 2: CLK_1 (/100)
    always @(posedge CLK_in or posedge RST) begin
        if (RST) begin
            CLK_1   <= 1'b0;
            cnt_100 <= 6'd0;
        end else if (cnt_100 == 6'd49) begin
            CLK_1   <= ~CLK_1;
            cnt_100 <= 6'd0;
        end else begin
            cnt_100 <= cnt_100 + 6'd1;
        end
    end

endmodule
