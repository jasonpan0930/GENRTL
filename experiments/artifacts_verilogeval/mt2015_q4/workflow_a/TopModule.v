// TopModule: top-level with A and B submodules
// SPEC: spec/design.spec.txt
//
// Ports:
//   x - input
//   y - input
//   z - output

module TopModule (
    input  x,
    input  y,
    output z
);

    wire a1_out, a2_out, b1_out, b2_out;
    wire or_out, and_out;

    A a1 (.x(x), .y(y), .z(a1_out));
    A a2 (.x(x), .y(y), .z(a2_out));
    B b1 (.x(x), .y(y), .z(b1_out));
    B b2 (.x(x), .y(y), .z(b2_out));

    assign or_out  = a1_out | b1_out;
    assign and_out = a2_out & b2_out;
    assign z       = or_out ^ and_out;

endmodule

// Module A: z = (x^y) & x
module A (
    input  x,
    input  y,
    output z
);

    assign z = (x ^ y) & x;

endmodule

// Module B: z = XNOR of x and y
module B (
    input  x,
    input  y,
    output z
);

    assign z = ~(x ^ y);

endmodule
