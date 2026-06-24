// Arbiter FSM — priority: device 0 > device 1 > device 2
module TopModule (
    input        clk,
    input        resetn,
    input  [2:0] r,
    output [2:0] g
);

    localparam A = 2'b00;
    localparam B = 2'b01;  // grant to device 0
    localparam C = 2'b10;  // grant to device 1
    localparam D = 2'b11;  // grant to device 2

    reg [1:0] state, next_state;

    // State register (synchronous active-low reset)
    always @(posedge clk) begin
        if (!resetn)
            state <= A;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            A: begin
                if (r[0])
                    next_state = B;
                else if (r[1])
                    next_state = C;
                else if (r[2])
                    next_state = D;
                else
                    next_state = A;
            end
            B: begin
                if (r[0])
                    next_state = B;
                else
                    next_state = A;
            end
            C: begin
                if (r[1])
                    next_state = C;
                else
                    next_state = A;
            end
            D: begin
                if (r[2])
                    next_state = D;
                else
                    next_state = A;
            end
        endcase
    end

    // Moore outputs
    assign g[0] = (state == B);
    assign g[1] = (state == C);
    assign g[2] = (state == D);

endmodule
