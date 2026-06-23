module sub_64bit (
    input  wire [63:0] A,
    input  wire [63:0] B,
    output reg  [63:0] result,
    output reg         overflow
);

    // ============================================================
    // Internal declarations
    // ============================================================
    wire [63:0] diff;

    // ============================================================
    // Combinational subtract & overflow detect
    // ============================================================
    assign diff = A - B;

    always @(*) begin
        result   = diff;
        overflow = ((!A[63]) && B[63] && diff[63]) ||
                   (A[63] && (!B[63]) && (!diff[63]));
    end

endmodule
