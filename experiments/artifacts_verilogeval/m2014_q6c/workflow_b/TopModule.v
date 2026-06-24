// Combinational next-state logic for one-hot FSM
// Computes Y2 (next state of y[1]=B) and Y4 (next state of y[3]=D)

module TopModule (
    input  [5:0] y,
    input        w,
    output       Y2,
    output       Y4
);

    // One-hot: y[0]=A, y[1]=B, y[2]=C, y[3]=D, y[4]=E, y[5]=F
    //
    // Y2 (next B) is set when A & ~w (A -> B transition)
    // Y4 (next D) is set when B|C|E|F & w (B/C/E/F -> D transitions)
    assign Y2 = y[0] & ~w;
    assign Y4 = w & (y[1] | y[2] | y[4] | y[5]);

endmodule
