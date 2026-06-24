// Gshare branch predictor: 7-bit PC, 7-bit global history, 128-entry 2-bit PHT
module TopModule (
    input         clk,
    input         areset,

    // Prediction interface (Fetch stage)
    input         predict_valid,
    input  [6:0]  predict_pc,
    output        predict_taken,
    output [6:0]  predict_history,

    // Training interface (Execute stage)
    input         train_valid,
    input         train_taken,
    input         train_mispredicted,
    input  [6:0]  train_history,
    input  [6:0]  train_pc
);

    // 128-entry PHT: 2-bit saturating counters
    reg [1:0] pht [0:127];

    // 7-bit global branch history register
    reg [6:0] global_history;

    // Prediction combinational
    wire [6:0] pred_index = predict_pc ^ global_history;
    assign predict_taken   = predict_valid ? pht[pred_index][1] : 1'b0;
    assign predict_history = global_history;

    // PHT update logic (sequential, at posedge)
    wire [6:0] train_index = train_pc ^ train_history;

    integer i;
    always @(posedge clk, posedge areset) begin
        if (areset) begin
            global_history <= 7'd0;
            for (i = 0; i < 128; i = i + 1)
                pht[i] <= 2'b01;  // weakly not-taken
        end else begin
            // Update global history: training (mispred) takes precedence
            if (train_valid && train_mispredicted) begin
                global_history <= {train_history[5:0], train_taken};
            end else if (predict_valid) begin
                global_history <= {global_history[5:0], predict_taken};
            end

            // Train PHT
            if (train_valid) begin
                if (train_taken && pht[train_index] != 2'b11)
                    pht[train_index] <= pht[train_index] + 1'b1;
                else if (!train_taken && pht[train_index] != 2'b00)
                    pht[train_index] <= pht[train_index] - 1'b1;
            end
        end
    end

endmodule
