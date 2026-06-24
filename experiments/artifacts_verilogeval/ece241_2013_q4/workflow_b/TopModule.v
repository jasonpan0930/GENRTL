// TopModule — ece241_2013_q4 (VerilogEval #149)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input        clk,
    input        reset,
    input  [2:0] s,
    output reg   fr2,
    output reg   fr1,
    output reg   fr0,
    output reg   dfr
);

    // Stage 0 — Level decode (combinational)
    reg  [1:0] level;
    reg        fr0_nom, fr1_nom, fr2_nom;

    always @(*) begin
        case (s)
            3'b111: begin
                level = 2'd3;
                {fr2_nom, fr1_nom, fr0_nom} = 3'b000;
            end
            3'b011: begin
                level = 2'd2;
                {fr2_nom, fr1_nom, fr0_nom} = 3'b001;
            end
            3'b001: begin
                level = 2'd1;
                {fr2_nom, fr1_nom, fr0_nom} = 3'b011;
            end
            3'b000: begin
                level = 2'd0;
                {fr2_nom, fr1_nom, fr0_nom} = 3'b111;
            end
            default: begin
                level = 2'd3;
                {fr2_nom, fr1_nom, fr0_nom} = 3'b000;
            end
        endcase
    end

    // Stage 0 — previous level register
    reg [1:0] prev_level;

    // Stage 0 — dfr combinational logic
    wire dfr_next;
    assign dfr_next = (level > prev_level) ? 1'b1 : 1'b0;

    // Stage 0 — output and prev_level registers
    always @(posedge clk) begin
        if (reset) begin
            fr2        <= 1'b1;
            fr1        <= 1'b1;
            fr0        <= 1'b1;
            dfr        <= 1'b1;
            prev_level <= 2'd0;
        end else begin
            fr2        <= fr2_nom;
            fr1        <= fr1_nom;
            fr0        <= fr0_nom;
            dfr        <= dfr_next;
            prev_level <= level;
        end
    end

endmodule
