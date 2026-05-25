# RTL 生成專案 — Agent 說明

比較 **Workflow A**（直接 SPEC→RTL）與 **Workflow B**（多階段 pipeline）。

## SPEC 輸入

- 位置：`spec/`
- 格式：`.md` 或 `.txt`（優先 `design.spec.md`，其次 `design.spec.txt`，否則 `spec/` 內唯一 spec 檔）
- SPEC 可用中文或英文
- **禁止**修改 `spec/` 原始檔；Workflow B 精煉結果 → `workflow-b-pipeline/spec_refined.md`
- **生成階段禁止**讀 `RTLLM/`、`verified_*.v`、`testbench.v`、`_chatgpt*`（見 `.cursorignore`）；評測在生成後另做

## Workflow A

- **Skill（建議）**：`@rtl-workflow-a`（`SKILL.zh.md`）
- 規則（輔助）：`@workflow-a.zh`
- 輸出：`workflow-a-direct/rtl/*.v`

## Workflow B

| Agent | 職責 | 輸出 |
|-------|------|------|
| Agent1 | SPEC 精煉 | `workflow-b-pipeline/spec_refined.md` |
| Agent2 | 時序 / combinational·sequential 規劃 | `workflow-b-pipeline/timing_plan.md` |
| Agent3 | RTL | `workflow-b-pipeline/rtl/*.v` |

協作：`collaboration_log.md`，最多 3 輪。**Skill（建議）**：`@rtl-pipeline-workflow-b`（`SKILL.zh.md`）

## 實驗

同一 `spec/` 輸入；紀錄於 `experiments/`
