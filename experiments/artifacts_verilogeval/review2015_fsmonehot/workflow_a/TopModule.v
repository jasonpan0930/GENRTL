// One-hot FSM next-state and output logic (combinational)
// 10 states: S, S1, S11, S110, B0, B1, B2, B3, Count, Wait
// Encoding: S=0, S1=1, S11=2, S110=3, B0=4, B1=5, B2=6, B3=7, Count=8, Wait=9
module TopModule (
    input        d,
    input        done_counting,
    input        ack,
    input  [9:0] state,
    output       B3_next,
    output       S_next,
    output       S1_next,
    output       Count_next,
    output       Wait_next,
    output       done,
    output       counting,
    output       shift_ena
);

    // Output logic (Moore)
    assign shift_ena = |{state[4], state[5], state[6], state[7]};  // B0|B1|B2|B3
    assign counting  = state[8];   // Count
    assign done      = state[9];   // Wait

    // Next-state logic for requested states
    // S_next: S&~d | S1&~d | S110&~d | Wait&ack
    assign S_next = (~d & (|{state[0], state[1], state[3]})) | (ack & state[9]);

    // S1_next: S&d
    assign S1_next = d & state[0];

    // B3_next: B2
    assign B3_next = state[6];

    // Count_next: B3 | Count&~done_counting
    assign Count_next = state[7] | (state[8] & ~done_counting);

    // Wait_next: Count&done_counting | Wait&~ack
    assign Wait_next = (state[8] & done_counting) | (state[9] & ~ack);

endmodule
