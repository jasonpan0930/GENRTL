// ============================================================================
// asyn_fifo — Asynchronous FIFO with configurable DEPTH and WIDTH
// ============================================================================
// Pipeline: Workflow B (Agent1→2→3)
// Stages: W0 (write counter), W1 (Gray conv), W2 (read-ptr sync),
//         W3 (full detect), R0 (read counter), R1 (Gray conv),
//         R2 (write-ptr sync), R3 (empty detect), M0 (dual_port_RAM)
// ============================================================================

module asyn_fifo #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
) (
    input  wire             wclk,
    input  wire             rclk,
    input  wire             wrstn,
    input  wire             rrstn,
    input  wire             winc,
    input  wire             rinc,
    input  wire [WIDTH-1:0] wdata,
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

    // -----------------------------------------------------------------------
    // Local parameters
    // -----------------------------------------------------------------------
    localparam ADDR_W = $clog2(DEPTH);            // RAM address width
    localparam PTR_W  = $clog2(DEPTH) + 1;        // Pointer width (extra MSB for full/empty)

    // -----------------------------------------------------------------------
    // Internal signals — declared before use (domain_knowledge §1)
    // -----------------------------------------------------------------------

    // Write domain (wclk)
    reg  [PTR_W-1:0] wbin;                        // Stage W0 — binary write pointer
    wire [PTR_W-1:0] wbin_next;                   // Stage W0 — next write pointer value
    wire [PTR_W-1:0] wptr;                        // Stage W1 — Gray-coded write pointer
    reg  [PTR_W-1:0] rptr_syn1, rptr_syn;         // Stage W2 — read-pointer synchronizer
    wire             wfull_int;                   // Stage W3 — full flag (internal)
    wire             wenc;                        // RAM write enable (gated)

    // Read domain (rclk)
    reg  [PTR_W-1:0] rbin;                        // Stage R0 — binary read pointer
    wire [PTR_W-1:0] rbin_next;                   // Stage R0 — next read pointer value
    wire [PTR_W-1:0] rptr;                        // Stage R1 — Gray-coded read pointer
    reg  [PTR_W-1:0] wptr_syn1, wptr_syn;         // Stage R2 — write-pointer synchronizer
    wire             rempty_int;                  // Stage R3 — empty flag (internal)
    wire             renc;                        // RAM read enable (gated)

    // RAM connections
    wire [ADDR_W-1:0] waddr;                      // RAM write address
    wire [ADDR_W-1:0] raddr;                      // RAM read address

    // -----------------------------------------------------------------------
    // Stage W0 — Write pointer counter (Sequential, wclk domain)
    // -----------------------------------------------------------------------
    assign wbin_next = (winc && !wfull_int) ? (wbin + 1'b1) : wbin;

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            wbin <= 0;
        end else if (winc && !wfull_int) begin
            wbin <= wbin_next;
        end
    end

    // -----------------------------------------------------------------------
    // Stage W1 — Gray code conversion (Combinational, wclk domain)
    // -----------------------------------------------------------------------
    assign wptr = wbin ^ (wbin >> 1);

    // -----------------------------------------------------------------------
    // Stage W2 — Read-pointer synchronizer (Sequential, wclk domain)
    // -----------------------------------------------------------------------
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rptr_syn1 <= 0;
            rptr_syn  <= 0;
        end else begin
            rptr_syn1 <= rptr;
            rptr_syn  <= rptr_syn1;
        end
    end

    // -----------------------------------------------------------------------
    // Stage W3 — Full flag generation (Combinational, wclk domain)
    // -----------------------------------------------------------------------
    assign wfull_int = (wptr[PTR_W-1] != rptr_syn[PTR_W-1]) &&
                       (wptr[PTR_W-2] != rptr_syn[PTR_W-2]) &&
                       (wptr[PTR_W-3:0] == rptr_syn[PTR_W-3:0]);

    assign wfull = wfull_int;

    // -----------------------------------------------------------------------
    // Stage R0 — Read pointer counter (Sequential, rclk domain)
    // -----------------------------------------------------------------------
    assign rbin_next = (rinc && !rempty_int) ? (rbin + 1'b1) : rbin;

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            rbin <= 0;
        end else if (rinc && !rempty_int) begin
            rbin <= rbin_next;
        end
    end

    // -----------------------------------------------------------------------
    // Stage R1 — Gray code conversion (Combinational, rclk domain)
    // -----------------------------------------------------------------------
    assign rptr = rbin ^ (rbin >> 1);

    // -----------------------------------------------------------------------
    // Stage R2 — Write-pointer synchronizer (Sequential, rclk domain)
    // -----------------------------------------------------------------------
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wptr_syn1 <= 0;
            wptr_syn  <= 0;
        end else begin
            wptr_syn1 <= wptr;
            wptr_syn  <= wptr_syn1;
        end
    end

    // -----------------------------------------------------------------------
    // Stage R3 — Empty flag generation (Combinational, rclk domain)
    // -----------------------------------------------------------------------
    assign rempty_int = (rptr == wptr_syn);
    assign rempty     = rempty_int;

    // -----------------------------------------------------------------------
    // RAM enable generation
    // -----------------------------------------------------------------------
    assign wenc = winc && !wfull_int;
    assign renc = rinc && !rempty_int;

    // -----------------------------------------------------------------------
    // RAM address (lower ADDR_W bits of binary pointer)
    // -----------------------------------------------------------------------
    assign waddr = wbin[ADDR_W-1:0];
    assign raddr = rbin[ADDR_W-1:0];

    // -----------------------------------------------------------------------
    // Stage M0 — dual_port_RAM submodule instantiation
    // -----------------------------------------------------------------------
    dual_port_RAM #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) u_ram (
        .wclk (wclk),
        .wenc (wenc),
        .waddr(waddr),
        .wdata(wdata),
        .rclk (rclk),
        .renc (renc),
        .raddr(raddr),
        .rdata(rdata)
    );

endmodule


// ============================================================================
// dual_port_RAM — Dual-port RAM submodule
// ============================================================================
// Separate write clock (wclk) and read clock (rclk).
// Write is enabled by wenc; read is enabled by renc (registered output).
// ----------------------------------------------------------------------------

module dual_port_RAM #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
) (
    input  wire                     wclk,
    input  wire                     wenc,
    input  wire [$clog2(DEPTH)-1:0] waddr,
    input  wire [WIDTH-1:0]         wdata,
    input  wire                     rclk,
    input  wire                     renc,
    input  wire [$clog2(DEPTH)-1:0] raddr,
    output reg  [WIDTH-1:0]         rdata
);

    // Memory array
    reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];

    // Write port (wclk domain)
    always @(posedge wclk) begin
        if (wenc) begin
            RAM_MEM[waddr] <= wdata;
        end
    end

    // Read port (rclk domain, registered output)
    always @(posedge rclk) begin
        if (renc) begin
            rdata <= RAM_MEM[raddr];
        end
    end

endmodule
