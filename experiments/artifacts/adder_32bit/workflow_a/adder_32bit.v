// adder_32bit — Carry-Lookahead Adder (CLA) 32-bit
//
// SPEC: spec/design.spec.txt
//   Ports: A[32:1], B[32:1] (input), S[32:1] (output), C32 (carry-out)
//   Architecture: two 16-bit CLA blocks (lower[15:1], upper[31:16])
//
// [ASSUMPTION] Carry-in to the lowest bit is 0 (no Cin port in SPEC).
// [ASSUMPTION] Ports use [32:1] convention per SPEC; internally mapped to [31:0].

// 4-bit Carry-Lookahead block
module cla_4bit (
    input  [3:0] A,
    input  [3:0] B,
    input        C_in,
    output [3:0] S,
    output       C_out,
    output       G_grp,   // group generate
    output       P_grp    // group propagate
);
    wire [3:0] G = A & B;
    wire [3:0] P = A ^ B;

    // Parallel carry computation
    wire [4:0] C;
    assign C[0] = C_in;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C[0]);
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1])
                | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C[0]);

    assign S     = P ^ C[3:0];
    assign C_out = C[4];
    assign G_grp = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);
    assign P_grp = &P;
endmodule


// 16-bit CLA built from four 4-bit CLAs with second-level lookahead
module cla_16bit (
    input  [15:0] A,
    input  [15:0] B,
    input         C_in,
    output [15:0] S,
    output        C_out
);
    wire [3:0] G_grp, P_grp;
    wire [4:0] C_grp;  // group carries

    assign C_grp[0] = C_in;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : cla4
            cla_4bit u (
                .A    (A[i*4 +: 4]),
                .B    (B[i*4 +: 4]),
                .C_in (C_grp[i]),
                .S    (S[i*4 +: 4]),
                .C_out(),
                .G_grp(G_grp[i]),
                .P_grp(P_grp[i])
            );
        end
    endgenerate

    // Second-level lookahead
    assign C_grp[1] = G_grp[0] | (P_grp[0] & C_grp[0]);
    assign C_grp[2] = G_grp[1] | (P_grp[1] & G_grp[0]) | (P_grp[1] & P_grp[0] & C_grp[0]);
    assign C_grp[3] = G_grp[2] | (P_grp[2] & G_grp[1]) | (P_grp[2] & P_grp[1] & G_grp[0])
                    | (P_grp[2] & P_grp[1] & P_grp[0] & C_grp[0]);
    assign C_grp[4] = G_grp[3] | (P_grp[3] & G_grp[2]) | (P_grp[3] & P_grp[2] & G_grp[1])
                    | (P_grp[3] & P_grp[2] & P_grp[1] & G_grp[0])
                    | (P_grp[3] & P_grp[2] & P_grp[1] & P_grp[0] & C_grp[0]);

    assign C_out = C_grp[4];
endmodule


// Top module: 32-bit adder using two 16-bit CLA blocks
module adder_32bit (
    input  [32:1] A,
    input  [32:1] B,
    output [32:1] S,
    output        C32
);
    wire c16;

    cla_16bit u_lower (
        .A    (A[16:1]),
        .B    (B[16:1]),
        .C_in (1'b0),
        .S    (S[16:1]),
        .C_out(c16)
    );

    cla_16bit u_upper (
        .A    (A[32:17]),
        .B    (B[32:17]),
        .C_in (c16),
        .S    (S[32:17]),
        .C_out(C32)
    );
endmodule
