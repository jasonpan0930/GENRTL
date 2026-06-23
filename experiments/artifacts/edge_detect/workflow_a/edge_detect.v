// edge_detect
// Detects rising and falling edges on input a.
// rise = 1 on cycle after 0->1 transition; down = 1 on cycle after 1->0 transition.

module edge_detect (
    input  clk,    // clock
    input  rst_n,  // active-low async reset
    input  a,      // input signal
    output rise,   // rising edge indicator
    output down    // falling edge indicator
);

    reg a_dly;  // delayed version of a

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            a_dly <= 1'b0;
        else
            a_dly <= a;
    end

    assign rise = a & ~a_dly;
    assign down = ~a & a_dly;

endmodule
