// Hierarchical combinational circuit
// Module A: z = (x^y) & x
// Module B: z = ~(x^y)

module TopModule (
    input  wire x,
    input  wire y,
    output wire z
);

    wire a1_out, b1_out;
    wire a2_out, b2_out;
    wire or_out, and_out;

    // First pair: A1 and B1 feeding OR
    A A1 (
        .x(x),
        .y(y),
        .z(a1_out)
    );
    B B1 (
        .x(x),
        .y(y),
        .z(b1_out)
    );
    assign or_out = a1_out | b1_out;

    // Second pair: A2 and B2 feeding AND
    A A2 (
        .x(x),
        .y(y),
        .z(a2_out)
    );
    B B2 (
        .x(x),
        .y(y),
        .z(b2_out)
    );
    assign and_out = a2_out & b2_out;

    // Final XOR
    assign z = or_out ^ and_out;

endmodule

// Submodule A: z = (x^y) & x = x & ~y
module A (
    input  wire x,
    input  wire y,
    output wire z
);
    assign z = (x ^ y) & x;
endmodule

// Submodule B: z = ~(x^y)
module B (
    input  wire x,
    input  wire y,
    output wire z
);
    assign z = ~(x ^ y);
endmodule
