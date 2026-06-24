// 10-state one-hot FSM next-state and output logic (combinational)
module TopModule (
    input  in,
    input  [9:0] state,
    output [9:0] next_state,
    output out1,
    output out2
);

    assign next_state[0] = (~in) & (|{state[0], state[1], state[2], state[3], state[4],
                                     state[7], state[8], state[9]});
    assign next_state[1] = in & (|{state[0], state[8], state[9]});
    assign next_state[2] = in & state[1];
    assign next_state[3] = in & state[2];
    assign next_state[4] = in & state[3];
    assign next_state[5] = in & state[4];
    assign next_state[6] = in & state[5];
    assign next_state[7] = in & (|{state[5], state[6]});
    assign next_state[8] = (~in) & state[5];
    assign next_state[9] = (~in) & state[6];

    // Outputs: S8=(1,0), S9=(1,1), S7=(0,1)
    assign out1 = state[8] | state[9];
    assign out2 = state[7] | state[9];

endmodule
