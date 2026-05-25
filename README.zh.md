# SPEC → RTL 實驗專案

比較兩種由 Cursor Agent 從硬體 SPEC 產生 Verilog RTL 的流程（評測建議搭配 **RTLLM** + **VCS**）。

## 目錄

| 路徑 | 用途 |
|------|------|
| `spec/` | 原始 SPEC（`.md` 或 `.txt`） |
| `workflow-a-direct/rtl/` | Workflow A：直接產生的 RTL |
| `workflow-b-pipeline/` | Workflow B：精煉 SPEC、時序規劃、協作紀錄、RTL |
| `.cursor/skills/rtl-workflow-a/` | Workflow A Skill |
| `.cursor/skills/rtl-pipeline-workflow-b/` | Workflow B Skill |
| `.cursor/rules/` | 輔助規則（路徑、Pass@1 禁止讀參考碼） |
| `prompts/` | 可選短指令（與 skill 對齊） |
| `experiments/` | 每次 run 紀錄 |
| `.cursorignore` | 降低索引到 RTLLM／參考 RTL 的機率 |

## 使用前

1. 將 RTLLM 的 `design_description.txt` 複製為 `spec/design.spec.md` 或 `spec/design.spec.txt`（**不要**只用 `*.example` 檔名）
2. **Open Folder** → 本 repo 根目錄（`myProject_GENRTL/`）
3. **Agent 模式**，每次實驗用**新對話**（Pass@1）

## Workflow A（建議只 @ skill）

```
@rtl-workflow-a
```

可補充：`SPEC: spec/design.spec.txt`

讀取 `.cursor/skills/rtl-workflow-a/SKILL.zh.md`。輸出：`workflow-a-direct/rtl/*.v`

## Workflow B（建議只 @ skill）

```
@rtl-pipeline-workflow-b
```

全流程：Agent1 → Agent2 →（協作 ≤3 輪）→ Agent3。讀取 `SKILL.zh.md`。

分階段：對話註明「僅 Agent1／Agent2／Agent3」，或見 `prompts/workflow-b-agent*.zh.md`

## VCS 評測（RTLLM）

生成完成後，**不要**讓 Agent 跑仿真。在終端：

```bash
RTLLM=/path/to/RTLLM/Arithmetic/Adder/<題目目錄>
cp workflow-a-direct/rtl/<模組>.v "$RTLLM/"   # 或 workflow-b-pipeline/rtl/
cd "$RTLLM" && make clean && make vcs && make sim
```

`adder_pipe_64bit` 等題的 testbench 使用 `[31:0]` 與 `clk`/`rst_n`；若 SPEC 寫 `[32:1]`，以 testbench 對齊方式在 SPEC 中寫清楚（生成階段仍勿讀 testbench）。

## Pass@1 公平性

生成時禁止讀：`RTLLM/`、`verified_*.v`、`testbench.v`、`_chatgpt*`。缺資訊用 `[ASSUMPTION]` 或停止。

## 實驗紀錄

見 `experiments/README.zh.md`（記錄 model、skill、SPEC 路徑、VCS 結果）。

## Verilog 慣例（共用）

- **有時序／pipeline**：單一 `clk`；預設 `rst_n` active-low 同步釋放
- **純組合（SPEC 無 clock）**：勿自行加 `clk`/`rst_n`
- 檔名 = 模組名；port 註解對應 SPEC 章節
