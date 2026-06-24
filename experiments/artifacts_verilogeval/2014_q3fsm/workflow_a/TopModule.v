// TopModule: FSM with s/w — checks w in 3-cycle windows, z=1 if exactly 2 w=1
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk   - clock (positive edge)
//   reset - synchronous active-high reset
//   s     - start signal (transitions A→B)
//   w     - input to check in 3-cycle windows
//   z     - asserted for one cycle after a window with exactly 2 w=1

module TopModule (
    input clk,
    input reset,
    input s,
    input w,
    output reg z
);

    reg [2:0] state;
    reg [1:0] cnt;

    localparam A = 3'd0,
               B = 3'd1,
               C = 3'd2,
               D = 3'd3,
               E = 3'd4;

    always @(posedge clk) begin
        if (reset) begin
            state <= A;
            cnt   <= 2'd0;
            z     <= 1'b0;
        end else begin
            z <= 1'b0;
            case (state)
                A: begin
                    cnt <= 2'd0;
                    if (s) state <= B;
                end
                B: begin
                    cnt   <= w ? 2'd1 : 2'd0;
                    state <= C;
                end
                C: begin
                    cnt   <= cnt + w;
                    state <= D;
                end
                D: begin
                    cnt   <= cnt + w;
                    state <= E;
                end
                E: begin
                    z     <= (cnt == 2'd2);
                    state <= B;
                end
            endcase
        end
    end

endmodule
