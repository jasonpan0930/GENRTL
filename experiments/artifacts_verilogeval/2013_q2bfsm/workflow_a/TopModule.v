// TopModule: motor controller FSM
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk    - clock (positive edge)
//   resetn - synchronous active-low reset
//   x      - motor input
//   y      - motor input
//   f      - asserted for one cycle after reset deasserts
//   g      - asserted after "101" pattern, then conditional on y

module TopModule (
    input  clk,
    input  resetn,
    input  x,
    input  y,
    output reg f,
    output reg g
);

    reg [3:0] state;

    localparam A     = 4'd0,
               F1    = 4'd1,
               S1    = 4'd2,
               S0    = 4'd3,
               S2    = 4'd4,
               G1    = 4'd5,
               G2    = 4'd6,
               G_ON  = 4'd7,
               G_OFF = 4'd8;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= A;
            f     <= 1'b0;
            g     <= 1'b0;
        end else begin
            f <= 1'b0;
            g <= 1'b0;
            case (state)
                A: begin
                    state <= F1;
                end
                F1: begin
                    f     <= 1'b1;
                    state <= S1;
                end
                S1: begin
                    if (x)
                        state <= S0;
                end
                S0: begin
                    if (x)
                        state <= S0;
                    else
                        state <= S2;
                end
                S2: begin
                    if (x) begin
                        g     <= 1'b1;
                        state <= G1;
                    end else begin
                        state <= S1;
                    end
                end
                G1: begin
                    g <= 1'b1;
                    if (y)
                        state <= G_ON;
                    else
                        state <= G2;
                end
                G2: begin
                    g <= 1'b1;
                    if (y)
                        state <= G_ON;
                    else
                        state <= G_OFF;
                end
                G_ON: begin
                    g     <= 1'b1;
                    state <= G_ON;
                end
                G_OFF: begin
                    state <= G_OFF;
                end
            endcase
        end
    end

endmodule
