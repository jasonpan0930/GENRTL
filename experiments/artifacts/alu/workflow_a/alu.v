// alu
// 32-bit MIPS-ISA ALU with all standard operations.

module alu (
    input  [31:0] a,       // operand A
    input  [31:0] b,       // operand B
    input  [5:0]  aluc,    // 6-bit opcode
    output [31:0] r,       // result
    output        zero,    // result == 0
    output        carry,   // carry / borrow
    output        negative,// result[31]
    output        overflow,// signed overflow
    output        flag     // SLT / SLTU indicator
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

    reg [31:0] res;
    wire [31:0] add_result = a + b;
    wire [31:0] sub_result = a - b;
    wire [32:0] add_ext    = {1'b0, a} + {1'b0, b};
    wire [32:0] sub_ext    = {1'b0, a} - {1'b0, b};

    always @(*) begin
        case (aluc)
            ADD, ADDU: res = add_result;
            SUB, SUBU: res = sub_result;
            AND:       res = a & b;
            OR:        res = a | b;
            XOR:       res = a ^ b;
            NOR:       res = ~(a | b);
            SLT:       res = {31'd0, ($signed(a) < $signed(b))};
            SLTU:      res = {31'd0, (a < b)};
            SLL, SLLV: res = b << a[4:0];
            SRL, SRLV: res = b >> a[4:0];
            SRA, SRAV: res = $signed(b) >>> a[4:0];
            LUI:       res = {a[15:0], 16'd0};
            default:   res = {32{1'bz}};
        endcase
    end

    assign r        = res;
    assign zero     = (res == 32'd0);
    assign negative = res[31];
    assign carry    = (aluc == SUB || aluc == SUBU) ? sub_ext[32] : add_ext[32];
    assign overflow = (aluc == ADD || aluc == ADDU) ? ( (a[31] == b[31] && res[31] != a[31]) ) :
                      (aluc == SUB || aluc == SUBU) ? ( (a[31] != b[31] && res[31] != a[31]) ) :
                      1'b0;
    assign flag     = (aluc == SLT || aluc == SLTU) ? 1'b1 : 1'bz;

endmodule
