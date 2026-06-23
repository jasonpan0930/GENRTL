module multi_16bit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [15:0] ain,
    input  wire [15:0] bin,
    output reg  [31:0] yout,
    output reg         done
);

    // ============================================================
    // Internal declarations
    // ============================================================
    reg  [4:0]  i;          // shift counter, 0..17
    reg [15:0]  areg;       // multiplicand register
    reg [15:0]  breg;       // multiplier register
    reg [31:0]  you_r;      // product accumulator
    reg         done_r;     // internal done flag

    // ============================================================
    // Stage 0: Counter, input latch & accumulation
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i     <= 5'd0;
            areg  <= 16'd0;
            breg  <= 16'd0;
            you_r <= 32'd0;
        end else if (start) begin
            if (i == 5'd0) begin
                areg <= ain;
                breg <= bin;
                i    <= i + 5'd1;
            end else if (i < 5'd17) begin
                if (areg[i-1]) begin
                    you_r <= you_r + ({16'd0, breg} << (i-1));
                end
                i <= i + 5'd1;
            end
        end else begin
            i <= 5'd0;
        end
    end

    // ============================================================
    // Stage 1: Done flag
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_r <= 1'd0;
        end else if (start && (i == 5'd16)) begin
            done_r <= 1'd1;
        end else if (start && (i == 5'd17)) begin
            done_r <= 1'd0;
        end
    end

    // ============================================================
    // Stage 2: Output assignment (combinational)
    // ============================================================
    always @(*) begin
        yout = you_r;
        done = done_r;
    end

endmodule
