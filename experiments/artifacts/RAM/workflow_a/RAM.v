// RAM
// Dual-port synchronous RAM: depth=8, width=6, all zeros on reset.
// [ASSUMPTION] SPEC WIDTH/DEPTH swapped in array declaration (§Implementation);
// implementing as depth=8, width=6 per module description.

module RAM #(
    parameter WIDTH = 6,
    parameter DEPTH = 8
) (
    input              clk,         // clock
    input              rst_n,       // active-low async reset
    input              write_en,    // write enable
    input  [2:0]       write_addr,  // write address (log2(DEPTH)=3)
    input  [WIDTH-1:0] write_data,  // data to write
    input              read_en,     // read enable
    input  [2:0]       read_addr,   // read address
    output [WIDTH-1:0] read_data    // read data
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];  // RAM array
    reg [WIDTH-1:0] read_data_reg;

    integer i;

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= {WIDTH{1'b0}};
        end else if (write_en) begin
            mem[write_addr] <= write_data;
        end
    end

    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            read_data_reg <= {WIDTH{1'b0}};
        else if (read_en)
            read_data_reg <= mem[read_addr];
        else
            read_data_reg <= {WIDTH{1'b0}};
    end

    assign read_data = read_data_reg;

endmodule
