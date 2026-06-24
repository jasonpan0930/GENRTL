// FSM: monitor w in 3-cycle windows after s=1
// z=1 if w=1 in exactly 2 of 3 cycles

module TopModule (
    input  wire clk,
    input  wire reset,
    input  wire s,
    input  wire w,
    output wire z
);

    localparam A  = 3'b000;
    localparam B1 = 3'b001;  // 1st cycle examining w
    localparam B2 = 3'b010;  // 2nd cycle examining w
    localparam B3 = 3'b011;  // 3rd cycle + evaluate
    localparam Z1 = 3'b100;  // z=1 result
    localparam Z0 = 3'b101;  // z=0 result

    reg [2:0] state;
    reg w1, w2;

    assign z = (state == Z1);

    always @(posedge clk) begin
        if (reset) begin
            state <= A;
        end else begin
            case (state)
                A: begin
                    if (s) begin
                        state <= B1;
                        w1    <= w;  // 1st sample (at entry to B)
                    end
                end

                B1: begin
                    w2    <= w;       // 2nd sample
                    state <= B2;
                end

                B2: begin
                    state <= B3;
                    // 3rd sample w is the current input at B3
                end

                B3: begin
                    if (w1 + w2 + w == 2'd2)
                        state <= Z1;
                    else
                        state <= Z0;
                end

                Z1: begin
                    state <= B1;
                    w1    <= w;       // 1st sample of next window
                end

                Z0: begin
                    state <= B1;
                    w1    <= w;       // 1st sample of next window
                end

                default: state <= A;
            endcase
        end
    end

endmodule
