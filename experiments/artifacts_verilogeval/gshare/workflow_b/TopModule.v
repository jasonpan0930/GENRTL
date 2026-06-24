// gshare (VerilogEval #153)
// TopModule: Gshare branch predictor, 7-bit PC+history, 128-entry 2-bit saturating counter PHT
// Asynchronous active-high reset, positive-edge clock

module TopModule (
    input        clk,
    input        areset,

    input        predict_valid,
    input  [6:0] predict_pc,
    output       predict_taken,
    output [6:0] predict_history,

    input        train_valid,
    input        train_taken,
    input        train_mispredicted,
    input  [6:0] train_history,
    input  [6:0] train_pc
);

    // Internal state
    reg [6:0] global_history;
    reg [1:0] pht [0:127];

    // Combinational: prediction index and taken
    wire [6:0] predict_idx = predict_pc ^ global_history;
    assign predict_taken = (pht[predict_idx] >= 2'd2);
    assign predict_history = global_history;

    // Combinational: training index
    wire [6:0] train_idx = train_pc ^ train_history;

    // Sequential
    integer i;
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            global_history <= 7'd0;
            for (i = 0; i < 128; i = i + 1)
                pht[i] <= 2'd2;
        end else begin
            // History update: training takes precedence
            if (train_valid && train_mispredicted)
                global_history <= {train_history[5:0], train_taken};
            else if (predict_valid)
                global_history <= {global_history[5:0], predict_taken};

            // PHT update on training
            if (train_valid) begin
                if (train_taken && (pht[train_idx] < 2'd3))
                    pht[train_idx] <= pht[train_idx] + 2'd1;
                else if (!train_taken && (pht[train_idx] > 2'd0))
                    pht[train_idx] <= pht[train_idx] - 2'd1;
            end
        end
    end

endmodule
