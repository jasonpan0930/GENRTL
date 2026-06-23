---
name: rtl-workflow-a
description: >-
  Workflow A：直接 SPEC → Verilog RTL（Pass@1）。使用者執行 Workflow A 或
  @rtl-workflow-a 時使用；讀取本檔（中文）。
---

# RTL Direct — Workflow A（中文）

## 目標

從 `spec/` 原始 SPEC **一次產生** Verilog，不經精煉或時序規劃。SPEC 可中/英。

## 啟動（建議）

使用者 **@rtl-workflow-a** 即執行本 skill。新對話、Pass@1：只生成一次，不讀仿真 log 迭代。

### 題號簡寫

可說 **`RTLLM #6`** 或 **`adder_pipe_64bit`**。
也可說 **`VerilogEval #1`** 或 **`zero`**；此時 top_module 固定為 `TopModule`。

#### 共通前置

0. **任務開始時**，Agent 在終端先執行：`source ~/source.sh`（載入 VCS；我們的 `scripts/*.sh` 也會自動 source）

#### RTLLM 流程

1.若使用者給 `RTLLM #N` 或題目 id，**Agent 在終端執行** `./scripts/prep_problem.sh <N|id>`
2. 讀 `experiments/.run_context.json` 與 `spec/design.spec.txt`
3. 頂層模組名 = `top_module`；輸出 `workflow-a-direct/rtl/<top_module>.v`
4. RTL 完成後 **Agent 執行** `./scripts/archive_run.sh a`
5. 若使用者說 **含評測** / `with eval`：**執行** `./scripts/run_vcs.sh a`，僅回報 CSV 結果

#### VerilogEval 流程

1. 若使用者給 `VerilogEval #N` 或題目 id，**Agent 在終端執行** `./scripts/prep_ve_problem.sh <N|id> --full-clean`
2. 讀 `experiments/.run_context.json` 與 `spec/design.spec.txt`
3. 頂層模組名固定為 `TopModule`；輸出 `workflow-a-direct/rtl/TopModule.v`
4. RTL 完成後，若使用者說 **含評測** / `with eval`：**執行** `./scripts/run_ve_sim.sh a <N>`，僅回報 CSV 結果

#### 通用規則

**Pass@1**：禁止依 VCS log 修改 RTL；禁止讀 testbench／verified／RefModule

可選：`SPEC: spec/design.spec.txt` · `with eval`

## SPEC 讀取順序

1. `spec/design.spec.md`
2. `spec/design.spec.txt`
3. `spec/` 內**唯一** `.md` / `.txt`（排除 `*.example`）
4. 找不到則回報並停止

## 禁止讀取（Pass@1）

勿讀 `RTLLM/`、`verified_*.v`、`testbench.v`、`_chatgpt35/`、`_chatgpt4/`。  
缺 port／模組名：列出缺失並停止，或標 `[ASSUMPTION]`；**勿**從 testbench／參考 RTL 補齊。

## 輸出

| 允許 | 禁止 |
|------|------|
| `workflow-a-direct/rtl/*.v` | 修改 `spec/` |
| | 寫入 `workflow-b-pipeline/` |

- `module_name.v` = 模組名（與 SPEC 一致）
- port 與 SPEC 一致；註解標 SPEC 章節
- **有 clock/reset 的設計**：單一 `clk`；預設 `rst_n` active-low 同步釋放
- **純組合（SPEC 無 clk）**：不要自行加 `clk`/`rst_n`
- 可綜合；組合邏輯 `always @(*)`，避免 latch
- 子模組可與 top 同檔（RTLLM 常只編譯 top `.v`）

## 流程

```
spec/（唯讀）→ 實作 RTL → workflow-a-direct/rtl/*.v
```

## 完成檢查

- [ ] 所有對外 port
- [ ] 無明顯多驅動／非預期組合迴路
- [ ] 列出 `[ASSUMPTION]`

## 回報

SPEC 路徑、`.v` 與模組列表、假設、`experiments/results.csv` 中本題 compile/sim 摘要。  
**Pass@1**：不因 VCS 失敗而改 RTL（延伸實驗 Repair@k 另議）。
