// TopModule: shift register enable FSM
// SPEC: spec/design.spec.txt
//
// Ports:
//   clk       - clock (positive edge)
//   reset     - synchronous active-high reset
//   shift_ena - asserted for 4 cycles after reset, then 0 forever

module TopModule (
    input clk,
    input reset,
    output reg shift_ena
);

    reg [1:0] cnt;

    always @(posedge clk) begin
        if (reset) begin
            cnt       <= 2'd0;
            shift_ena <= 1'b1;
        end else if (shift_ena) begin
            if (cnt == 2'd3) begin
                shift_ena <= 1'b0;
            end else begin
                cnt <= cnt + 1'd1;
            end
        end
    end

endmodule
