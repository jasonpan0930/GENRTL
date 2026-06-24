// ============================================================================
// barrel_shifter — 8-bit rotate-left barrel shifter
// ============================================================================
// Pipeline: Workflow B (Agent1→2→3)
// Stages: Stage2 (rotate by 4), Stage1 (rotate by 2), Stage0 (rotate by 1)
// Each stage uses 8× mux2X1 submodule instances.
// ============================================================================

module barrel_shifter (
    input  wire [7:0] in,
    input  wire [2:0] ctrl,
    output wire [7:0] out
);

    // -----------------------------------------------------------------------
    // Internal signals — declared before use (domain_knowledge §1)
    // Stage 2 output, Stage 1 output
    // -----------------------------------------------------------------------
    wire [7:0] s2_out;   // Stage 2 — rotate by 4
    wire [7:0] s1_out;   // Stage 1 — rotate by 2

    // -----------------------------------------------------------------------
    // Stage 2 — Rotate by 4 (ctrl[2])
    // 8× mux2X1: each selects between in[i] and in[(i+4)%8]
    // -----------------------------------------------------------------------
    mux2X1 u_s2_mux0 (.a(in[0]), .b(in[4]), .sel(ctrl[2]), .out(s2_out[0]));
    mux2X1 u_s2_mux1 (.a(in[1]), .b(in[5]), .sel(ctrl[2]), .out(s2_out[1]));
    mux2X1 u_s2_mux2 (.a(in[2]), .b(in[6]), .sel(ctrl[2]), .out(s2_out[2]));
    mux2X1 u_s2_mux3 (.a(in[3]), .b(in[7]), .sel(ctrl[2]), .out(s2_out[3]));
    mux2X1 u_s2_mux4 (.a(in[4]), .b(in[0]), .sel(ctrl[2]), .out(s2_out[4]));
    mux2X1 u_s2_mux5 (.a(in[5]), .b(in[1]), .sel(ctrl[2]), .out(s2_out[5]));
    mux2X1 u_s2_mux6 (.a(in[6]), .b(in[2]), .sel(ctrl[2]), .out(s2_out[6]));
    mux2X1 u_s2_mux7 (.a(in[7]), .b(in[3]), .sel(ctrl[2]), .out(s2_out[7]));

    // -----------------------------------------------------------------------
    // Stage 1 — Rotate by 2 (ctrl[1])
    // 8× mux2X1: each selects between s2_out[i] and s2_out[(i+2)%8]
    // -----------------------------------------------------------------------
    mux2X1 u_s1_mux0 (.a(s2_out[0]), .b(s2_out[2]), .sel(ctrl[1]), .out(s1_out[0]));
    mux2X1 u_s1_mux1 (.a(s2_out[1]), .b(s2_out[3]), .sel(ctrl[1]), .out(s1_out[1]));
    mux2X1 u_s1_mux2 (.a(s2_out[2]), .b(s2_out[4]), .sel(ctrl[1]), .out(s1_out[2]));
    mux2X1 u_s1_mux3 (.a(s2_out[3]), .b(s2_out[5]), .sel(ctrl[1]), .out(s1_out[3]));
    mux2X1 u_s1_mux4 (.a(s2_out[4]), .b(s2_out[6]), .sel(ctrl[1]), .out(s1_out[4]));
    mux2X1 u_s1_mux5 (.a(s2_out[5]), .b(s2_out[7]), .sel(ctrl[1]), .out(s1_out[5]));
    mux2X1 u_s1_mux6 (.a(s2_out[6]), .b(s2_out[0]), .sel(ctrl[1]), .out(s1_out[6]));
    mux2X1 u_s1_mux7 (.a(s2_out[7]), .b(s2_out[1]), .sel(ctrl[1]), .out(s1_out[7]));

    // -----------------------------------------------------------------------
    // Stage 0 — Rotate by 1 (ctrl[0])
    // 8× mux2X1: each selects between s1_out[i] and s1_out[(i+1)%8]
    // -----------------------------------------------------------------------
    mux2X1 u_s0_mux0 (.a(s1_out[0]), .b(s1_out[1]), .sel(ctrl[0]), .out(out[0]));
    mux2X1 u_s0_mux1 (.a(s1_out[1]), .b(s1_out[2]), .sel(ctrl[0]), .out(out[1]));
    mux2X1 u_s0_mux2 (.a(s1_out[2]), .b(s1_out[3]), .sel(ctrl[0]), .out(out[2]));
    mux2X1 u_s0_mux3 (.a(s1_out[3]), .b(s1_out[4]), .sel(ctrl[0]), .out(out[3]));
    mux2X1 u_s0_mux4 (.a(s1_out[4]), .b(s1_out[5]), .sel(ctrl[0]), .out(out[4]));
    mux2X1 u_s0_mux5 (.a(s1_out[5]), .b(s1_out[6]), .sel(ctrl[0]), .out(out[5]));
    mux2X1 u_s0_mux6 (.a(s1_out[6]), .b(s1_out[7]), .sel(ctrl[0]), .out(out[6]));
    mux2X1 u_s0_mux7 (.a(s1_out[7]), .b(s1_out[0]), .sel(ctrl[0]), .out(out[7]));

endmodule


// ============================================================================
// mux2X1 — 1-bit 2-to-1 multiplexer
// ============================================================================
// out = sel ? b : a;
// ----------------------------------------------------------------------------

module mux2X1 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire out
);

    assign out = sel ? b : a;

endmodule
