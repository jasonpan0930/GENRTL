// ============================================================================
// LIFObuffer.v
// Last-In-First-Out stack buffer — 4-deep, 4-bit
// Ref: spec_refined.md §1–§7, timing_plan.md §3
// ============================================================================
// Port order (positional — must match spec_refined §2.1 / §8 A6):
//   dataIn, RW, EN, Rst, Clk, EMPTY, FULL, dataOut
// ============================================================================

module LIFObuffer (
    dataIn, RW, EN, Rst, Clk, EMPTY, FULL, dataOut
);

    // ------------------------------------------------------------------
    // Port declarations (spec_refined §2.1)
    // ------------------------------------------------------------------
    input  [3:0] dataIn;        // Data to push when RW=0
    input        RW;            // 1=read(pop), 0=write(push)
    input        EN;            // Enable: 1=operation, 0=hold
    input        Rst;           // Synchronous active-HIGH reset (§2.3)
    input        Clk;           // Rising-edge clock
    output       EMPTY;         // 1 when SP==4 (§3.2)
    output       FULL;          // 1 when SP==0 (§3.2)
    output reg [3:0] dataOut;   // Popped data; zero on reset

    // ------------------------------------------------------------------
    // Internal signal declarations (domain_knowledge §1 — declare before use)
    // ------------------------------------------------------------------
    // Stage 0 — Combinational control (timing_plan §3 Stage 0)
    wire        do_push;        // Push enable: EN & ~RW & ~FULL
    wire        do_pop;         // Pop enable:  EN &  RW & ~EMPTY
    wire [2:0]  sp_next;        // Next SP value (decrement / increment / hold)
    wire        wen;            // Stack write enable (= do_push)
    wire [2:0]  wr_addr;        // Pre-decrement write address (= sp - 1)

    // Stage 1 — Sequential state (timing_plan §3 Stage 1)
    reg  [2:0]  sp;             // Stack pointer, 3 bits (range 0..4) (§3.1)
    reg  [3:0]  stack_mem [0:3]; // 4-entry × 4-bit register array (§1)

    // ------------------------------------------------------------------
    // Stage 0: Combinational control logic  (timing_plan §3 Stage 0)
    // ------------------------------------------------------------------
    // Flag generation (§3.2)
    assign FULL   = (sp == 3'b000);    // FULL  when stack is full  (SP==0)
    assign EMPTY  = (sp == 3'b100);    // EMPTY when stack is empty (SP==4)

    // Operation decode (§3.3, §3.4)
    assign do_push = EN & ~RW & ~FULL;  // Push when enabled, write, not full
    assign do_pop  = EN &  RW & ~EMPTY; // Pop  when enabled, read,  not empty

    // Next SP — three-way mux: decrement (push), increment (pop), hold (§3.1)
    assign sp_next = do_push ? (sp - 3'b001) :
                    (do_pop  ? (sp + 3'b001) : sp);

    // Stack write enable and address (timing_plan §3 Stage 0)
    assign wen     = do_push;
    assign wr_addr = sp - 3'b001;       // pre-decrement: data lands at SP-1

    // ------------------------------------------------------------------
    // Stage 1: Sequential state update  (timing_plan §3 Stage 1)
    // ------------------------------------------------------------------
    // SP register — 3-bit counter (§3.1)
    // Saturation is implicit: when FULL, do_push=0 → sp_next=sp;
    // when EMPTY, do_pop=0 → sp_next=sp.
    always @(posedge Clk) begin
        if (EN) begin
            if (Rst) begin
                sp <= 3'b100;           // reset to empty (SP=4) (§2.3)
            end else begin
                sp <= sp_next;          // push decrements, pop increments
            end
        end
    end

    // stack_mem — 4-entry × 4-bit register array (§1, §3.3, §3.4)
    always @(posedge Clk) begin
        if (EN) begin
            if (Rst) begin
                stack_mem[0] <= 4'b0000;    // clear all entries (§2.3)
                stack_mem[1] <= 4'b0000;
                stack_mem[2] <= 4'b0000;
                stack_mem[3] <= 4'b0000;
            end else begin
                if (do_push) begin
                    stack_mem[wr_addr] <= dataIn;   // push: write at SP-1 (§3.3)
                end
                if (do_pop) begin
                    stack_mem[sp] <= 4'b0000;       // pop: clear popped entry (§3.4, §7.7)
                end
            end
        end
    end

    // dataOut output register (§3.4, §2.3)
    always @(posedge Clk) begin
        if (EN) begin
            if (Rst) begin
                dataOut <= 4'b0000;         // reset to zero (§2.3)
            end else if (do_pop) begin
                dataOut <= stack_mem[sp];   // pop: output top-of-stack (§3.4)
            end
        end
    end

endmodule
