module instr_reg (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] fetch,
    input  wire [7:0] data,
    output reg  [2:0] ins,
    output reg  [4:0] ad1,
    output reg  [7:0] ad2
);

    reg [7:0] ins_p1;
    reg [7:0] ins_p2;

    always @(posedge clk) begin
        if (!rst) begin
            ins_p1 <= 8'd0;
            ins_p2 <= 8'd0;
        end else if (fetch == 2'b01) begin
            ins_p1 <= data;
        end else if (fetch == 2'b10) begin
            ins_p2 <= data;
        end
    end

    always @(*) begin
        ins = ins_p1[7:5];
        ad1 = ins_p1[4:0];
        ad2 = ins_p2;
    end

endmodule
