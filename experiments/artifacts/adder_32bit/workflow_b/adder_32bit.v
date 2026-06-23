//======================================================================
// adder_32bit — 32-bit Carry-Lookahead Adder (combinational)
// Ports use [32:1] convention per original SPEC.
//======================================================================

module adder_32bit (
    input  wire [32:1] A,
    input  wire [32:1] B,
    output wire [32:1] S,
    output wire        C32
);

    // Internal signals
    wire       carry_16;

    // Lower 16 bits [16:1]
    cla_16bit u_lower (
        .A   (A[16:1]),
        .B   (B[16:1]),
        .Cin (1'b0),
        .S   (S[16:1]),
        .Cout(carry_16)
    );

    // Upper 16 bits [32:17]
    cla_16bit u_upper (
        .A   (A[32:17]),
        .B   (B[32:17]),
        .Cin (carry_16),
        .S   (S[32:17]),
        .Cout(C32)
    );

endmodule


//======================================================================
// cla_16bit — 16-bit Carry-Lookahead Adder block
//======================================================================

module cla_16bit (
    input  wire [16:1] A,
    input  wire [16:1] B,
    input  wire        Cin,
    output wire [16:1] S,
    output wire        Cout
);

    // Internal signals
    wire [4:1] p_group;
    wire [4:1] g_group;
    wire [5:1] c;

    // Carry chain
    assign c[1] = Cin;

    // 4-bit CLA blocks
    cla_4bit u0 (.A(A[4:1]),  .B(B[4:1]),  .Cin(c[1]), .S(S[4:1]),
                 .Cout(), .P_group(p_group[1]), .G_group(g_group[1]));
    cla_4bit u1 (.A(A[8:5]),  .B(B[8:5]),  .Cin(c[2]), .S(S[8:5]),
                 .Cout(), .P_group(p_group[2]), .G_group(g_group[2]));
    cla_4bit u2 (.A(A[12:9]), .B(B[12:9]), .Cin(c[3]), .S(S[12:9]),
                 .Cout(), .P_group(p_group[3]), .G_group(g_group[3]));
    cla_4bit u3 (.A(A[16:13]),.B(B[16:13]),.Cin(c[4]), .S(S[16:13]),
                 .Cout(), .P_group(p_group[4]), .G_group(g_group[4]));

    // Lookahead carry logic
    assign c[2] = g_group[1] | (p_group[1] & c[1]);
    assign c[3] = g_group[2] | (p_group[2] & g_group[1]) | (p_group[2] & p_group[1] & c[1]);
    assign c[4] = g_group[3] | (p_group[3] & g_group[2]) |
                  (p_group[3] & p_group[2] & g_group[1]) |
                  (p_group[3] & p_group[2] & p_group[1] & c[1]);
    assign c[5] = g_group[4] | (p_group[4] & g_group[3]) |
                  (p_group[4] & p_group[3] & g_group[2]) |
                  (p_group[4] & p_group[3] & p_group[2] & g_group[1]) |
                  (p_group[4] & p_group[3] & p_group[2] & p_group[1] & c[1]);

    assign Cout = c[5];

endmodule


//======================================================================
// cla_4bit — 4-bit Carry-Lookahead Adder block
//======================================================================

module cla_4bit (
    input  wire [4:1] A,
    input  wire [4:1] B,
    input  wire       Cin,
    output wire [4:1] S,
    output wire       Cout,
    output wire       P_group,
    output wire       G_group
);

    // Internal signals
    wire [4:1] p;
    wire [4:1] g;
    wire [5:1] c;

    // Bit-level propagate and generate
    assign p[1] = A[1] ^ B[1];
    assign p[2] = A[2] ^ B[2];
    assign p[3] = A[3] ^ B[3];
    assign p[4] = A[4] ^ B[4];

    assign g[1] = A[1] & B[1];
    assign g[2] = A[2] & B[2];
    assign g[3] = A[3] & B[3];
    assign g[4] = A[4] & B[4];

    // Carry chain
    assign c[1] = Cin;
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & c[1]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) |
                  (p[3] & p[2] & p[1] & c[1]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) |
                  (p[4] & p[3] & p[2] & g[1]) |
                  (p[4] & p[3] & p[2] & p[1] & c[1]);

    // Sum
    assign S[1] = p[1] ^ c[1];
    assign S[2] = p[2] ^ c[2];
    assign S[3] = p[3] ^ c[3];
    assign S[4] = p[4] ^ c[4];

    // Group propagate and generate
    assign P_group = p[1] & p[2] & p[3] & p[4];
    assign G_group = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) |
                     (p[4] & p[3] & p[2] & g[1]);

    assign Cout = c[5];

endmodule
