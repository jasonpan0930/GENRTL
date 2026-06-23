// Module: adder_8bit
// Description: 8-bit ripple-carry adder constructed from bit-level full adders
// SPEC: spec/design.spec.txt

module adder_8bit (
    input  [7:0] a,      // Operand A
    input  [7:0] b,      // Operand B
    input        cin,    // Carry-in
    output [7:0] sum,    // Sum output
    output       cout    // Carry-out
);

    wire [8:0] carry;    // Internal carry chain (carry[0] = cin, carry[8] = cout)

    assign carry[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : full_adder_chain
            assign {carry[i+1], sum[i]} = a[i] + b[i] + carry[i];
        end
    endgenerate

    assign cout = carry[8];

endmodule
