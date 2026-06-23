// barrel_shifter
// 8-bit barrel shifter for rotating bits, purely combinational.
// Three stages: shift by 4 (ctrl[2]), 2 (ctrl[1]), 1 (ctrl[0]).
// Uses mux2X1 submodule instances per SPEC §Implementation.

module barrel_shifter (
    input  [7:0] in,      // 8-bit input to be shifted
    input  [2:0] ctrl,    // 3-bit control: bit2=shift4, bit1=shift2, bit0=shift1
    output [7:0] out      // 8-bit shifted output
);

    wire [7:0] stage0;    // after shift-by-4 stage
    wire [7:0] stage1;    // after shift-by-2 stage

    //----------------------------------------------------------------------
    // Stage 0: shift by 4 (ctrl[2])
    //----------------------------------------------------------------------
    generate
        genvar i;
        for (i = 0; i < 8; i = i + 1) begin : sh4
            mux2X1 u_mux (
                .a   (in[i]),           // unshifted
                .b   (in[(i + 4) % 8]), // shifted by 4 (rotated)
                .sel (ctrl[2]),
                .y   (stage0[i])
            );
        end
    endgenerate

    //----------------------------------------------------------------------
    // Stage 1: shift by 2 (ctrl[1])
    //----------------------------------------------------------------------
    generate
        genvar j;
        for (j = 0; j < 8; j = j + 1) begin : sh2
            mux2X1 u_mux (
                .a   (stage0[j]),           // unshifted
                .b   (stage0[(j + 2) % 8]), // shifted by 2 (rotated)
                .sel (ctrl[1]),
                .y   (stage1[j])
            );
        end
    endgenerate

    //----------------------------------------------------------------------
    // Stage 2: shift by 1 (ctrl[0])
    //----------------------------------------------------------------------
    generate
        genvar k;
        for (k = 0; k < 8; k = k + 1) begin : sh1
            mux2X1 u_mux (
                .a   (stage1[k]),           // unshifted
                .b   (stage1[(k + 1) % 8]), // shifted by 1 (rotated)
                .sel (ctrl[0]),
                .y   (out[k])
            );
        end
    endgenerate

endmodule


//----------------------------------------------------------------------
// mux2X1: 2-to-1 multiplexer submodule (SPEC §Implementation)
//----------------------------------------------------------------------
module mux2X1 (
    input  a,
    input  b,
    input  sel,
    output y
);
    assign y = sel ? b : a;
endmodule
