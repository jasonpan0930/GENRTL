// barrel_shifter — 8-bit barrel shifter (left-rotate)
// SPEC refined: workflow-b-pipeline/spec_refined.md
// Timing plan: workflow-b-pipeline/timing_plan.md
//
// Architecture: three cascaded combinational stages
//   Stage4 (ctrl[2]): rotate by 4
//   Stage2 (ctrl[1]): rotate by 2
//   Stage1 (ctrl[0]): rotate by 1

// --------------------------------------------------------
// Submodule: mux2X1 — 2-to-1 multiplexer
// --------------------------------------------------------
module mux2X1 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);
    assign y = sel ? b : a;
endmodule

// --------------------------------------------------------
// Top module: barrel_shifter
// --------------------------------------------------------
module barrel_shifter (
    input  wire [7:0] in,
    input  wire [2:0] ctrl,
    output wire [7:0] out
);

    // Internal wires (declared before use per domain_knowledge §1)
    wire [7:0] stage4_out;  // output of Stage 4
    wire [7:0] stage2_out;  // output of Stage 2

    // ----------------------------------------------------
    // Stage 4 — Rotate by 4 (controlled by ctrl[2])
    // ----------------------------------------------------
    // Each bit i gets either in[i] (no shift) or in[(i+4)%8] (rotate left by 4)
    mux2X1 u_mux4_0 (.a(in[0]), .b(in[4]), .sel(ctrl[2]), .y(stage4_out[0]));
    mux2X1 u_mux4_1 (.a(in[1]), .b(in[5]), .sel(ctrl[2]), .y(stage4_out[1]));
    mux2X1 u_mux4_2 (.a(in[2]), .b(in[6]), .sel(ctrl[2]), .y(stage4_out[2]));
    mux2X1 u_mux4_3 (.a(in[3]), .b(in[7]), .sel(ctrl[2]), .y(stage4_out[3]));
    mux2X1 u_mux4_4 (.a(in[4]), .b(in[0]), .sel(ctrl[2]), .y(stage4_out[4]));
    mux2X1 u_mux4_5 (.a(in[5]), .b(in[1]), .sel(ctrl[2]), .y(stage4_out[5]));
    mux2X1 u_mux4_6 (.a(in[6]), .b(in[2]), .sel(ctrl[2]), .y(stage4_out[6]));
    mux2X1 u_mux4_7 (.a(in[7]), .b(in[3]), .sel(ctrl[2]), .y(stage4_out[7]));

    // ----------------------------------------------------
    // Stage 2 — Rotate by 2 (controlled by ctrl[1])
    // ----------------------------------------------------
    // Each bit i gets either stage4_out[i] or stage4_out[(i+2)%8]
    mux2X1 u_mux2_0 (.a(stage4_out[0]), .b(stage4_out[2]), .sel(ctrl[1]), .y(stage2_out[0]));
    mux2X1 u_mux2_1 (.a(stage4_out[1]), .b(stage4_out[3]), .sel(ctrl[1]), .y(stage2_out[1]));
    mux2X1 u_mux2_2 (.a(stage4_out[2]), .b(stage4_out[4]), .sel(ctrl[1]), .y(stage2_out[2]));
    mux2X1 u_mux2_3 (.a(stage4_out[3]), .b(stage4_out[5]), .sel(ctrl[1]), .y(stage2_out[3]));
    mux2X1 u_mux2_4 (.a(stage4_out[4]), .b(stage4_out[6]), .sel(ctrl[1]), .y(stage2_out[4]));
    mux2X1 u_mux2_5 (.a(stage4_out[5]), .b(stage4_out[7]), .sel(ctrl[1]), .y(stage2_out[5]));
    mux2X1 u_mux2_6 (.a(stage4_out[6]), .b(stage4_out[0]), .sel(ctrl[1]), .y(stage2_out[6]));
    mux2X1 u_mux2_7 (.a(stage4_out[7]), .b(stage4_out[1]), .sel(ctrl[1]), .y(stage2_out[7]));

    // ----------------------------------------------------
    // Stage 1 — Rotate by 1 (controlled by ctrl[0])
    // ----------------------------------------------------
    // Each bit i gets either stage2_out[i] or stage2_out[(i+1)%8]
    mux2X1 u_mux1_0 (.a(stage2_out[0]), .b(stage2_out[1]), .sel(ctrl[0]), .y(out[0]));
    mux2X1 u_mux1_1 (.a(stage2_out[1]), .b(stage2_out[2]), .sel(ctrl[0]), .y(out[1]));
    mux2X1 u_mux1_2 (.a(stage2_out[2]), .b(stage2_out[3]), .sel(ctrl[0]), .y(out[2]));
    mux2X1 u_mux1_3 (.a(stage2_out[3]), .b(stage2_out[4]), .sel(ctrl[0]), .y(out[3]));
    mux2X1 u_mux1_4 (.a(stage2_out[4]), .b(stage2_out[5]), .sel(ctrl[0]), .y(out[4]));
    mux2X1 u_mux1_5 (.a(stage2_out[5]), .b(stage2_out[6]), .sel(ctrl[0]), .y(out[5]));
    mux2X1 u_mux1_6 (.a(stage2_out[6]), .b(stage2_out[7]), .sel(ctrl[0]), .y(out[6]));
    mux2X1 u_mux1_7 (.a(stage2_out[7]), .b(stage2_out[0]), .sel(ctrl[0]), .y(out[7]));

endmodule
