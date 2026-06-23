// ROM
// 256x16 read-only memory, combinational read.

module ROM (
    input  [7:0]  addr,  // 8-bit address
    output [15:0] dout   // 16-bit data output
);

    reg [15:0] mem [0:255];  // 256 x 16 ROM array

    initial begin
        mem[0] = 16'hA0A0;
        mem[1] = 16'hB1B1;
        mem[2] = 16'hC2C2;
        mem[3] = 16'hD3D3;
    end

    reg [15:0] dout_reg;
    always @(*) begin
        dout_reg = mem[addr];
    end
    assign dout = dout_reg;

endmodule
