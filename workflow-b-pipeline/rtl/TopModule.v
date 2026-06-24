// TopModule — gshare branch predictor (VerilogEval #153)
// Ref: spec_refined.md §3, timing_plan.md Stage 0

module TopModule (
    input         clk,
    input         areset,

    // Prediction interface
    input         predict_valid,
    input  [6:0]  predict_pc,
    output        predict_taken,
    output [6:0]  predict_history,

    // Training interface
    input         train_valid,
    input         train_taken,
    input         train_mispredicted,
    input  [6:0]  train_history,
    input  [6:0]  train_pc
);

    // Stage 0 — Global history register (Sequential, with async reset)
    reg [6:0] history;

    always @(posedge clk or posedge areset) begin
        if (areset)
            history <= 7'd0;
        else if (train_valid)
            history <= {train_history[5:0], train_taken};
        else if (predict_valid)
            history <= {history[5:0], predict_taken};
    end

    // Stage 0 — PHT: 128 entries x 2-bit saturating counters
    reg [1:0] pht [0:127];

    // PHT read index for prediction (combinational)
    wire [6:0] pred_idx = predict_pc ^ history;
    wire [1:0] pred_ctr = pht[pred_idx];

    // Prediction outputs (combinational)
    assign predict_taken    = (predict_valid) ? pred_ctr[1] : 1'b0;
    assign predict_history  = (predict_valid) ? history : 7'd0;

    // PHT write index for training
    wire [6:0] train_idx = train_pc ^ train_history;

    // Stage 0 — PHT update (Sequential, at clock edge)
    always @(posedge clk) begin
        if (train_valid) begin
            if (train_taken) begin
                if (pht[train_idx] != 2'b11)
                    pht[train_idx] <= pht[train_idx] + 2'd1;
            end else begin
                if (pht[train_idx] != 2'b00)
                    pht[train_idx] <= pht[train_idx] - 2'd1;
            end
        end
    end

endmodule
