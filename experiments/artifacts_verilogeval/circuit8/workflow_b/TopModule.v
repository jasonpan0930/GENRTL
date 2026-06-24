// circuit8 (VerilogEval #145)
// TopModule: Positive-level latch (p) + Negedge flip-flop (q)

module TopModule (
    input  clock,
    input  a,
    output p,
    output q
);

    reg p;
    reg q;

    // Positive-level sensitive latch: p follows a when clock=1
    always @(*) begin
        if (clock)
            p = a;
    end

    // Negedge-triggered flip-flop: q captures p on falling edge
    always @(negedge clock) begin
        q <= p;
    end

endmodule
