// calendar
// Perpetual calendar: counts HH:MM:SS (0-23 / 0-59 / 0-59).

module calendar (
    input       CLK,   // clock
    input       RST,   // active-high async reset
    output [5:0] Hours, // hours (0-23)
    output [5:0] Mins,  // minutes (0-59)
    output [5:0] Secs   // seconds (0-59)
);

    reg [5:0] secs_reg;
    reg [5:0] mins_reg;
    reg [5:0] hours_reg;

    // Seconds counter (0-59)
    always @(posedge CLK or posedge RST) begin
        if (RST)
            secs_reg <= 6'd0;
        else if (secs_reg == 6'd59)
            secs_reg <= 6'd0;
        else
            secs_reg <= secs_reg + 1'd1;
    end

    assign Secs = secs_reg;

    // Minutes counter (0-59); increments when Secs==59
    always @(posedge CLK or posedge RST) begin
        if (RST)
            mins_reg <= 6'd0;
        else if (mins_reg == 6'd59 && secs_reg == 6'd59)
            mins_reg <= 6'd0;
        else if (secs_reg == 6'd59)
            mins_reg <= mins_reg + 1'd1;
    end

    assign Mins = mins_reg;

    // Hours counter (0-23); increments when Mins==59 && Secs==59
    always @(posedge CLK or posedge RST) begin
        if (RST)
            hours_reg <= 6'd0;
        else if (hours_reg == 6'd23 && mins_reg == 6'd59 && secs_reg == 6'd59)
            hours_reg <= 6'd0;
        else if (mins_reg == 6'd59 && secs_reg == 6'd59)
            hours_reg <= hours_reg + 1'd1;
    end

    assign Hours = hours_reg;

endmodule
