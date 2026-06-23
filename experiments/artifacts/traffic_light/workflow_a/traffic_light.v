// traffic_light
// Traffic light controller with pedestrian button.
// Normal: green=60, yellow=5, red=10 cycles.
// pass_request during green: shorten remaining to 10 if >10.

module traffic_light (
    input        clk,           // clock
    input        rst_n,         // active-low async reset
    input        pass_request,  // pedestrian button
    output [7:0] clock,         // internal counter value
    output       red,
    output       yellow,
    output       green
);

    localparam IDLE     = 2'd0,
               S1_RED   = 2'd1,
               S2_YELLOW = 2'd2,
               S3_GREEN  = 2'd3;

    reg [1:0] state, next_state;
    reg [7:0] cnt;
    reg       red_o, yellow_o, green_o;
    reg       p_red, p_yellow, p_green;  // previous values

    // State transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:     next_state = S1_RED;
            S1_RED:   if (cnt == 8'd1) next_state = S3_GREEN;
            S3_GREEN: if (cnt == 8'd1) next_state = S2_YELLOW;
            S2_YELLOW: if (cnt == 8'd1) next_state = S1_RED;
            default:  next_state = IDLE;
        endcase
    end

    // Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 8'd10;
        else if (pass_request && green_o)
            cnt <= 8'd10;
        else if (!green_o && p_green)
            cnt <= 8'd60;
        else if (!yellow_o && p_yellow)
            cnt <= 8'd5;
        else if (!red_o && p_red)
            cnt <= 8'd10;
        else
            cnt <= cnt - 1'd1;
    end

    assign clock = cnt;

    // Output registers (previous values)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            red_o    <= 1'b0;
            yellow_o <= 1'b0;
            green_o  <= 1'b0;
        end else begin
            red_o    <= (state == S1_RED);
            yellow_o <= (state == S2_YELLOW);
            green_o  <= (state == S3_GREEN);
        end
    end

    // Track previous values for edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_red    <= 1'b0;
            p_yellow <= 1'b0;
            p_green  <= 1'b0;
        end else begin
            p_red    <= red_o;
            p_yellow <= yellow_o;
            p_green  <= green_o;
        end
    end

    assign red    = red_o;
    assign yellow = yellow_o;
    assign green  = green_o;

endmodule
