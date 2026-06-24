// TopModule: D latch
// SPEC: spec/design.spec.txt
//
// Ports:
//   d   - data input
//   ena - enable (latch transparent when high)
//   q   - output

module TopModule (
    input  d,
    input  ena,
    output reg q
);

    always @* begin
        if (ena)
            q = d;
    end

endmodule
