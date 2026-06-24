// Motor controller FSM
// resetn: sync active-low. After reset: f=1 for 1 cycle.
// Then detect x=1,0,1 → g=1.
// Then if y=1 within 2 cycles → g=1 permanently; else g=0 permanently.

module TopModule (
    input  wire       clk,
    input  wire       resetn,
    input  wire       x,
    input  wire       y,
    output reg        f,
    output reg        g
);

    localparam A      = 4'd0;  // idle, wait for resetn=1
    localparam F1     = 4'd1;  // f=1 pulse
    localparam X1     = 4'd2;  // look for x=1
    localparam X2     = 4'd3;  // saw 1, look for 0
    localparam X3     = 4'd4;  // saw 10, look for 1
    localparam G1     = 4'd5;  // g=1, check y (1st cycle)
    localparam G2     = 4'd6;  // g=1, check y (2nd cycle)
    localparam G_PERM = 4'd7;  // g=1 permanently
    localparam G_FAIL = 4'd8;  // g=0 permanently

    reg [3:0] state;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= A;
            f <= 1'b0;
            g <= 1'b0;
        end else begin
            case (state)
                A: begin
                    f <= 1'b0;
                    g <= 1'b0;
                    state <= F1;
                end

                F1: begin
                    f <= 1'b1;
                    state <= X1;
                end

                X1: begin
                    f <= 1'b0;
                    if (x) state <= X2;
                end

                X2: begin
                    if (x) state <= X2;      // still looking for 0
                    else   state <= X3;
                end

                X3: begin
                    if (x) state <= G1;      // 101 pattern matched!
                    else   state <= X1;      // pattern broken
                end

                G1: begin
                    g <= 1'b1;
                    if (y) state <= G_PERM;
                    else   state <= G2;
                end

                G2: begin
                    if (y) state <= G_PERM;
                    else   state <= G_FAIL;
                end

                G_PERM: begin
                    g <= 1'b1;  // sticky
                end

                G_FAIL: begin
                    g <= 1'b0;  // sticky
                end

                default: state <= A;
            endcase
        end
    end

endmodule
