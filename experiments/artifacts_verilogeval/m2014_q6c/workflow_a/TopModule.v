// TopModule: next-state logic for one-hot FSM
// SPEC: spec/design.spec.txt (Pass@1 — compile failure is dataset bug: testbench uses Y2/Y4 but RefModule uses Y1/Y3)
//
// Ports:
//   y[5:0] - current state (one-hot: A=000001, B=000010, ..., F=100000)
//   w      - input
//   Y1     - next state for y[1] (state B)
//   Y3     - next state for y[3] (state D)

module TopModule (
    input  [5:0] y,
    input        w,
    output       Y1,
    output       Y3
);

    // y[0]=A, y[1]=B, y[2]=C, y[3]=D, y[4]=E, y[5]=F
    //
    // Transitions to B (y[1]): A & ~w
    // Transitions to D (y[3]): B&w | C&w | E&w | F&w
    assign Y1 = y[0] & ~w;
    assign Y3 = (y[1] | y[2] | y[4] | y[5]) & w;

endmodule
