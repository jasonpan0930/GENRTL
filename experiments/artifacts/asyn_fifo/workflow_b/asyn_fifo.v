//==============================================================================
// Module      : asyn_fifo
// Description : Asynchronous (dual-clock) FIFO with configurable width and
//               depth. Write and read clocks are independent. Uses dual-port
//               RAM + Gray-code pointer crossing + two-stage synchronizers.
// Spec        : spec_refined.md
// Timing Plan : timing_plan.md (Stage 0–3)
//==============================================================================

module asyn_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    // Port order MUST match testbench positional mapping:
    // wclk, rclk, wrstn, rrstn, winc, rinc, wdata, wfull, rempty, rdata
    input  wire                wclk,
    input  wire                rclk,
    input  wire                wrstn,   // active-low reset, write domain
    input  wire                rrstn,   // active-low reset, read domain
    input  wire                winc,    // write increment
    input  wire                rinc,    // read increment
    input  wire [WIDTH-1:0]    wdata,   // write data
    output wire                wfull,   // FIFO full flag
    output wire                rempty,  // FIFO empty flag
    output wire [WIDTH-1:0]    rdata    // read data
);

    // -----------------------------------------------------------------------
    // Localparams (spec_refined §4.8)
    // -----------------------------------------------------------------------
    localparam C_PTR_W = $clog2(DEPTH) + 1;  // pointer width (incl. MSB)
    localparam C_ADDR_W = $clog2(DEPTH);     // RAM address width
    localparam W_MSB = C_PTR_W - 1;          // MSB index of pointer

    // =======================================================================
    // Internal wire / reg declarations (domain_knowledge §1 — declare before
    // any assign / always / instance)
    // =======================================================================

    // --- Write-domain registers (Stage 1 — timing_plan §3 Stage 1) ---------
    reg [C_PTR_W-1:0] waddr_bin;     // binary write pointer
    reg [C_PTR_W-1:0] wptr;          // registered Gray-coded write pointer
    reg [C_PTR_W-1:0] rptr_buff;     // synchronizer stage 1 (read ptr in)
    reg [C_PTR_W-1:0] rptr_syn;      // synchronizer stage 2 (synced read ptr)

    // --- Write-domain combinational wires (Stage 0 — timing_plan §3 Stage 0)
    wire [C_PTR_W-1:0] waddr_bin_next;  // next binary write pointer value
    wire [C_PTR_W-1:0] wptr_comb;       // combinational Gray-coded wptr
    wire                wenc;            // write enable to dual_port_RAM
    wire [C_ADDR_W-1:0] waddr;          // RAM write address

    // --- Read-domain registers (Stage 3 — timing_plan §3 Stage 3) ----------
    reg [C_PTR_W-1:0] raddr_bin;     // binary read pointer
    reg [C_PTR_W-1:0] rptr;          // registered Gray-coded read pointer
    reg [C_PTR_W-1:0] wptr_buff;     // synchronizer stage 1 (write ptr in)
    reg [C_PTR_W-1:0] wptr_syn;      // synchronizer stage 2 (synced write ptr)

    // --- Read-domain combinational wires (Stage 2 — timing_plan §3 Stage 2)
    wire [C_PTR_W-1:0] raddr_bin_next;  // next binary read pointer value
    wire [C_PTR_W-1:0] rptr_comb;       // combinational Gray-coded rptr
    wire                renc;            // read enable to dual_port_RAM
    wire [C_ADDR_W-1:0] raddr;          // RAM read address

    // =======================================================================
    // Combinational logic — Write domain  (timing_plan Stage 0)
    // =======================================================================

    // §4.2 — write-pointer increment (mux)
    // spec_refined §4.2: waddr_bin <= waddr_bin + 1 when winc & !wfull
    assign waddr_bin_next = (winc & ~wfull) ? (waddr_bin + 1'b1) : waddr_bin;

    // §4.2 — binary to Gray conversion (uses next-pointer for registered
    // output, ensuring wptr always matches the registered waddr_bin)
    assign wptr_comb = waddr_bin_next ^ (waddr_bin_next >> 1);

    // §4.7 — full flag (combinational, uses registered wptr and rptr_syn)
    // spec_refined §4.7: MSBs opposite, lower bits equal → full
    assign wfull = (wptr[W_MSB]   != rptr_syn[W_MSB])
                && (wptr[W_MSB-1] != rptr_syn[W_MSB-1])
                && (wptr[W_MSB-2:0] == rptr_syn[W_MSB-2:0]);

    // §4.2 — write-enable gating
    // spec_refined §5.1: wenc = winc & !wfull
    assign wenc = winc & ~wfull;

    // §4.1 — RAM write address = lower C_ADDR_W bits of binary pointer
    assign waddr = waddr_bin[C_ADDR_W-1:0];

    // =======================================================================
    // Combinational logic — Read domain   (timing_plan Stage 2)
    // =======================================================================

    // §4.3 — read-pointer increment (mux)
    // spec_refined §4.3: raddr_bin <= raddr_bin + 1 when rinc & !rempty
    assign raddr_bin_next = (rinc & ~rempty) ? (raddr_bin + 1'b1) : raddr_bin;

    // §4.3 — binary to Gray conversion
    assign rptr_comb = raddr_bin_next ^ (raddr_bin_next >> 1);

    // §4.6 — empty flag (combinational)
    // spec_refined §4.6: rempty = (rptr == wptr_syn)
    assign rempty = (rptr == wptr_syn);

    // §4.3 — read-enable gating
    // spec_refined §5.2: renc = rinc & !rempty
    assign renc = rinc & ~rempty;

    // §4.1 — RAM read address = lower C_ADDR_W bits of binary pointer
    assign raddr = raddr_bin[C_ADDR_W-1:0];

    // =======================================================================
    // Sequential logic — Write domain   (timing_plan Stage 1)
    // =======================================================================
    // spec_refined §3.3: all write-domain regs reset to 0 on negedge wrstn
    // spec_refined §3.2: asynchronous assert (negedge in sensitivity list)

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= {(C_PTR_W){1'b0}};  // spec_refined §3.3 table
            wptr      <= {(C_PTR_W){1'b0}};
            rptr_buff <= {(C_PTR_W){1'b0}};
            rptr_syn  <= {(C_PTR_W){1'b0}};
        end else begin
            // §4.2 — binary pointer update
            waddr_bin <= waddr_bin_next;
            // §4.2 — registered Gray pointer (for full-flag and synchronizer)
            wptr      <= wptr_comb;
            // §4.4 — two-stage synchronizer for read pointer
            rptr_buff <= rptr;          // capture read-domain Gray pointer
            rptr_syn  <= rptr_buff;     // second synchronizer stage
        end
    end

    // =======================================================================
    // Sequential logic — Read domain    (timing_plan Stage 3)
    // =======================================================================
    // spec_refined §3.3: all read-domain regs reset to 0 on negedge rrstn

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= {(C_PTR_W){1'b0}};  // spec_refined §3.3 table
            rptr      <= {(C_PTR_W){1'b0}};
            wptr_buff <= {(C_PTR_W){1'b0}};
            wptr_syn  <= {(C_PTR_W){1'b0}};
        end else begin
            // §4.3 — binary pointer update
            raddr_bin <= raddr_bin_next;
            // §4.3 — registered Gray pointer (for empty-flag and synchronizer)
            rptr      <= rptr_comb;
            // §4.5 — two-stage synchronizer for write pointer
            wptr_buff <= wptr;          // capture write-domain Gray pointer
            wptr_syn  <= wptr_buff;     // second synchronizer stage
        end
    end

    // =======================================================================
    // Submodule instantiation — dual_port_RAM  (spec_refined §4.1)
    // Named port mapping (domain_knowledge §1.3, user requirement #4)
    // =======================================================================

    dual_port_RAM #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
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


//==============================================================================
// Module      : dual_port_RAM
// Description : True dual-port RAM — DEPTH entries of WIDTH bits each.
//               Write port: synchronous (posedge wclk, gated by wenc).
//               Read port : registered output (posedge rclk, gated by renc),
//                            1-cycle read latency per spec_refined.
// Spec        : spec_refined.md §4.1, timing_plan.md "dual_port_RAM submodule"
//==============================================================================

module dual_port_RAM #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input  wire                wclk,
    input  wire                wenc,
    input  wire [$clog2(DEPTH)-1:0] waddr,
    input  wire [WIDTH-1:0]    wdata,
    input  wire                rclk,
    input  wire                renc,
    input  wire [$clog2(DEPTH)-1:0] raddr,
    output reg  [WIDTH-1:0]    rdata
);

    // Memory array declaration
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Write port — synchronous write on posedge wclk when wenc asserted
    // spec_refined §5.1: write occurs same cycle winc is asserted
    // Domain knowledge §6.1: use localparam for array bounds with arithmetic
    always @(posedge wclk) begin
        if (wenc) begin
            mem[waddr] <= wdata;
        end
    end

    // Read port — registered output, 1-cycle read latency
    // spec_refined §5.2: rdata valid one rclk cycle after read address presented
    always @(posedge rclk) begin
        if (renc) begin
            rdata <= mem[raddr];
        end
    end

endmodule
