// alu — 32-bit MIPS ALU

module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [5:0]  aluc,
    output [31:0] r,
    output        zero,
    output        carry,
    output        negative,
    output        overflow,
    output        flag
);

    parameter ADD  = 6'b100000;
    parameter ADDU = 6'b100001;
    parameter SUB  = 6'b100010;
    parameter SUBU = 6'b100011;
    parameter AND  = 6'b100100;
    parameter OR   = 6'b100101;
    parameter XOR  = 6'b100110;
    parameter NOR  = 6'b100111;
    parameter SLT  = 6'b101010;
    parameter SLTU = 6'b101011;
    parameter SLL  = 6'b000000;
    parameter SRL  = 6'b000010;
    parameter SRA  = 6'b000011;
    parameter SLLV = 6'b000100;
    parameter SRLV = 6'b000110;
    parameter SRAV = 6'b000111;
    parameter LUI  = 6'b001111;

    wire signed [31:0] a_signed;
    wire signed [31:0] b_signed;

    reg [32:0] res;

    assign a_signed = a;
    assign b_signed = b;
    assign r = res[31:0];

    assign flag = (aluc == SLT || aluc == SLTU) ? ((aluc == SLT) ? (a_signed < b_signed) : (a < b)) : 1'bz;
    assign zero = (res == 32'b0) ? 1'b1 : 1'b0;

    always @(a or b or aluc) begin
        case (aluc)
            ADD:   res <= a_signed + b_signed;
            ADDU:  res <= a + b;
            SUB:   res <= a_signed - b_signed;
            SUBU:  res <= a - b;
            AND:   res <= a & b;
            OR:    res <= a | b;
            XOR:   res <= a ^ b;
            NOR:   res <= ~(a | b);
            SLT:   res <= a_signed < b_signed ? 1 : 0;
            SLTU:  res <= a < b ? 1 : 0;
            SLL:   res <= b << a;
            SRL:   res <= b >> a;
            SRA:   res <= b_signed >>> a_signed;
            SLLV:  res <= b << a[4:0];
            SRLV:  res <= b >> a[4:0];
            SRAV:  res <= b_signed >>> a_signed[4:0];
            LUI:   res <= {a[15:0], 16'h0000};
            default: res <= 32'bz;
        endcase
    end

endmodule
