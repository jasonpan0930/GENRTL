# SPEC → RTL 實驗專案

比較兩種由 Cursor Agent 從硬體 SPEC 產生 Verilog RTL 的流程。

## 目錄

| 路徑 | 用途 |
|------|------|
| `spec/` | 原始 SPEC（`.md` 或 `.txt`） |
| `workflow-a-direct/rtl/` | Workflow A：直接產生的 RTL |
| `workflow-b-pipeline/` | Workflow B：精煉 SPEC、時序規劃、協作紀錄、RTL |
| `prompts/` | 固定 prompt（`*.zh.md` / `*.en.md`） |
| `.cursor/rules/` | Workflow A / B 規則（`*.zh.mdc` / `*.en.mdc`） |
| `.cursor/skills/rtl-pipeline-workflow-b/` | Workflow B Skill（`SKILL.zh.md` / `SKILL.en.md`） |

## 使用前

1. 將 SPEC 放到 `spec/`：`design.spec.md` 或 `design.spec.txt`（中/英皆可）
2. 在 Cursor 開啟本專案資料夾

## Workflow A

複製 `prompts/workflow-a.zh.md`，或：

```
請依 @workflow-a.zh 規則執行 Workflow A。
```

## Workflow B

複製 `prompts/workflow-b-full.zh.md`，或：

```
請依 @rtl-pipeline-workflow-b skill 執行 Workflow B（讀取 SKILL.zh.md）。
```

分階段：`workflow-b-agent1.zh.md` → `agent2` → `agent3`

## 實驗紀錄

見 `experiments/README.zh.md`

## Verilog 慣例（共用）

- 單一 `clk`；預設 `rst_n` active-low 同步釋放
- 檔名 = 模組名
- port 註解標註 SPEC 章節
