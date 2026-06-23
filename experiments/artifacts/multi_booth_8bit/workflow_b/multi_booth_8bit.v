module multi_booth_8bit (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [15:0] p,
    output reg         rdy
);

    // ============================================================
    // Internal declarations
    // ============================================================
    reg  [15:0] multiplier;    // multiplier register (sign-extended)
    reg  [15:0] multiplicand;  // multiplicand register (sign-extended)
    reg  [4:0]  ctr;           // cycle counter, 0..16
    reg  [15:0] p_reg;         // product register
    reg         rdy_reg;       // ready flag

    // ============================================================
    // Stage 0: Core multiply & counter
    // ============================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            multiplier   <= {{8{a[7]}}, a};
            multiplicand <= {{8{b[7]}}, b};
            ctr          <= 5'd0;
            p_reg        <= 16'd0;
            rdy_reg      <= 1'd0;
        end else if (ctr < 5'd16) begin
            multiplicand <= multiplicand << 1;
            if (multiplier[ctr]) begin
                p_reg <= p_reg + multiplicand;
            end
            ctr <= ctr + 5'd1;
            if (ctr == 5'd15) begin
                rdy_reg <= 1'd1;
            end
        end
    end

    // ============================================================
    // Stage 1: Output assignment (combinational)
    // ============================================================
    always @(*) begin
        p   = p_reg;
        rdy = rdy_reg;
    end

endmodule
