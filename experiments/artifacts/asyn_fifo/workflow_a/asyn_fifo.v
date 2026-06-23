// asyn_fifo - Asynchronous FIFO with configurable DEPTH and WIDTH
// Spec: spec/design.spec.txt

module dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire                       wclk,
    input  wire                       wenc,
    input  wire [$clog2(DEPTH)-1:0]   waddr,
    input  wire [WIDTH-1:0]           wdata,
    input  wire                       rclk,
    input  wire                       renc,
    input  wire [$clog2(DEPTH)-1:0]   raddr,
    output reg  [WIDTH-1:0]           rdata
);

    localparam ADDR_W = $clog2(DEPTH);

    reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];

    // Write port
    always @(posedge wclk) begin
        if (wenc)
            RAM_MEM[waddr] <= wdata;
    end

    // Read port
    always @(posedge rclk) begin
        if (renc)
            rdata <= RAM_MEM[raddr];
    end

endmodule

module asyn_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire               wclk,
    input  wire               rclk,
    input  wire               wrstn,
    input  wire               rrstn,
    input  wire               winc,
    input  wire               rinc,
    input  wire [WIDTH-1:0]   wdata,
    output wire               wfull,
    output wire               rempty,
    output wire [WIDTH-1:0]   rdata
);

    // Pointer width = address bits + 1 (extra MSB for full/empty detection)
    localparam PTR_W = $clog2(DEPTH) + 1;
    localparam ADDR_W = $clog2(DEPTH);

    // --------------------------------------------------------------
    // Write clock domain
    // --------------------------------------------------------------
    reg [PTR_W-1:0] waddr_bin;
    reg [PTR_W-1:0] wptr;           // Gray code write pointer
    reg [PTR_W-1:0] rptr_syn_1;     // 1st stage sync of read pointer
    reg [PTR_W-1:0] rptr_syn_2;     // 2nd stage sync of read pointer
    wire [PTR_W-1:0] rptr_syn;

    wire wenc_ram;

    assign rptr_syn = rptr_syn_2;

    // Binary write pointer
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn)
            waddr_bin <= {PTR_W{1'b0}};
        else if (winc && !wfull)
            waddr_bin <= waddr_bin + 1'b1;
    end

    // Binary to Gray conversion
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn)
            wptr <= {PTR_W{1'b0}};
        else
            wptr <= (waddr_bin >> 1) ^ waddr_bin;
    end

    // Synchronize read pointer into write clock domain (two-stage)
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rptr_syn_1 <= {PTR_W{1'b0}};
            rptr_syn_2 <= {PTR_W{1'b0}};
        end else begin
            rptr_syn_1 <= rptr;
            rptr_syn_2 <= rptr_syn_1;
        end
    end

    // Full flag: MSBs differ, remaining bits same
    // wptr[PTR_W-1] != rptr_syn[PTR_W-1] && wptr[PTR_W-2] != rptr_syn[PTR_W-2]
    // && wptr[PTR_W-3:0] == rptr_syn[PTR_W-3:0]
    assign wfull = (wptr[PTR_W-1] != rptr_syn[PTR_W-1])
                 && (wptr[PTR_W-2] != rptr_syn[PTR_W-2])
                 && (wptr[PTR_W-3:0] == rptr_syn[PTR_W-3:0]);

    assign wenc_ram = winc && !wfull;

    // --------------------------------------------------------------
    // Read clock domain
    // --------------------------------------------------------------
    reg [PTR_W-1:0] raddr_bin;
    reg [PTR_W-1:0] rptr;           // Gray code read pointer
    reg [PTR_W-1:0] wptr_syn_1;     // 1st stage sync of write pointer
    reg [PTR_W-1:0] wptr_syn_2;     // 2nd stage sync of write pointer
    wire [PTR_W-1:0] wptr_syn;

    wire renc_ram;

    assign wptr_syn = wptr_syn_2;

    // Binary read pointer
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn)
            raddr_bin <= {PTR_W{1'b0}};
        else if (rinc && !rempty)
            raddr_bin <= raddr_bin + 1'b1;
    end

    // Binary to Gray conversion
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn)
            rptr <= {PTR_W{1'b0}};
        else
            rptr <= (raddr_bin >> 1) ^ raddr_bin;
    end

    // Synchronize write pointer into read clock domain (two-stage)
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wptr_syn_1 <= {PTR_W{1'b0}};
            wptr_syn_2 <= {PTR_W{1'b0}};
        end else begin
            wptr_syn_1 <= wptr;
            wptr_syn_2 <= wptr_syn_1;
        end
    end

    // Empty flag: pointers equal
    assign rempty = (rptr == wptr_syn);

    assign renc_ram = rinc && !rempty;

    // --------------------------------------------------------------
    // Dual-port RAM instance
    // --------------------------------------------------------------
    dual_port_RAM #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) u_ram (
        .wclk (wclk),
        .wenc (wenc_ram),
        .waddr(waddr_bin[ADDR_W-1:0]),
        .wdata(wdata),
        .rclk (rclk),
        .renc (renc_ram),
        .raddr(raddr_bin[ADDR_W-1:0]),
        .rdata(rdata)
    );

endmodule
