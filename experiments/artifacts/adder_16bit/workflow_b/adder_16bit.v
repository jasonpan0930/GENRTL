//==============================================================================
// adder_16bit — 16-bit full adder using two 8-bit adder submodules
// Stage 0: lower 8-bit addition (U_LOW)
// Stage 1: upper 8-bit addition (U_HIGH)
//==============================================================================

module adder_16bit (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        Cin,
    output wire [15:0] y,
    output wire        Co
);

    // Internal signals
    wire carry_mid;  // carry from low 8-bit adder to high 8-bit adder

    // Stage 0: lower 8-bit addition (bits 7:0)
    adder_8bit U_LOW (
        .a   (a[7:0]),
        .b   (b[7:0]),
        .Cin (Cin),
        .y   (y[7:0]),
        .Co  (carry_mid)
    );

    // Stage 1: upper 8-bit addition (bits 15:8) with carry from Stage 0
    adder_8bit U_HIGH (
        .a   (a[15:8]),
        .b   (b[15:8]),
        .Cin (carry_mid),
        .y   (y[15:8]),
        .Co  (Co)
    );

endmodule


//==============================================================================
// adder_8bit — 8-bit full adder submodule (combinational)
//==============================================================================

module adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       Cin,
    output wire [7:0] y,
    output wire       Co
);

    // Extended sum to capture carry-out
    wire [8:0] sum_ext;

    // Extend operands to 9 bits so the carry-out is not truncated
    assign sum_ext = {1'b0, a} + {1'b0, b} + Cin;
    assign y       = sum_ext[7:0];
    assign Co      = sum_ext[8];

endmodule
