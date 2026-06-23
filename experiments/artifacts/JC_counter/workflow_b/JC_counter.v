module JC_counter (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [63:0] Q
);

    // ============================================================
    // Internal declarations
    // ============================================================
    reg [63:0] Q_reg;

    // ============================================================
    // Stage 0: Johnson counter register
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Q_reg <= 64'd0;
        end else if (!Q_reg[0]) begin
            Q_reg <= {1'b1, Q_reg[63:1]};
        end else begin
            Q_reg <= {1'b0, Q_reg[63:1]};
        end
    end

    // ============================================================
    // Stage 1: Output assignment (combinational)
    // ============================================================
    always @(*) begin
        Q = Q_reg;
    end

endmodule
