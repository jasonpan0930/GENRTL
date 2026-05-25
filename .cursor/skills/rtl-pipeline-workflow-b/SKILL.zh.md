---
name: rtl-pipeline-workflow-b
description: >-
  Workflow B 多 Agent：SPEC 精煉（Agent1）、時序規劃（Agent2，與 Agent1 協作）、
  Verilog RTL（Agent3）。執行 Workflow B 或 Agent1/2/3 時使用；讀取本檔（中文）。
---

# RTL Pipeline — Workflow B（中文）

## 目標

不修改 `spec/` 原始 SPEC，經精煉與時序規劃產生一致 Verilog。SPEC 原文可中/英；`spec_refined.md` 建議與原文同語言。

## 啟動（建議）

使用者 **@rtl-pipeline-workflow-b** 即執行本 skill（全流程預設 Agent1→2→協作→3）。新對話、Pass@1。  
分階段時使用者指明「僅 Agent1／Agent2／Agent3」。可選：`SPEC 路徑為 spec/design.spec.txt`。

## SPEC 讀取

1. `spec/design.spec.md`
2. `spec/design.spec.txt`
3. `spec/` 內唯一 `.md` / `.txt`（排除 `*.example`）

## 禁止讀取（Pass@1）

勿讀 `RTLLM/`、`verified_*.v`、`testbench.v`、`_chatgpt35/`、`_chatgpt4/`。缺 port／行為僅用 `[ASSUMPTION]` 或停止。

---

## Agent1 — SPEC 精煉

**輸出**：`workflow-b-pipeline/spec_refined.md`

1. 保留原始需求
2. 補全 port、位寬、clock/reset、協定、邊界
3. 模糊句改為可驗證條目（若…則…）
4. 章節 **假設與決議**：`[ASSUMPTION]`
5. **與原始 SPEC 差異**
6. **待 Agent2 確認**

**禁止**：Verilog；完整 timing_plan（可寫介面時序約束）。

---

## Agent2 — 時序與結構

**輸入**：`spec_refined.md`（可對照 `spec/`，不改原始檔）

**輸出**：`workflow-b-pipeline/timing_plan.md`（格式見 [reference.zh.md](reference.zh.md)）

1. Stage 0, 1, 2…
2. 每 stage：`Combinational` / `Sequential` / `Mixed`
3. 跨 stage 信號：名、寬、是否註冊、握手
4. Sequential：clock edge、reset
5. 頂層 FSM（若有）

**協作**（≤3 輪，`collaboration_log.md`）：

| 情況 | 動作 |
|------|------|
| 與 spec_refined 矛盾 | log：**Round N**，Issue / Proposed fix / Owner → 更新檔 + **Resolution** |
| 缺假設 | plan 標 `[ASSUMPTION]`，請 Agent1 補 spec |
| 對齊 | **Status: ALIGNED** → Agent3 |

**禁止**：Verilog。

---

## Agent3 — RTL

**僅讀**：

- `spec_refined.md`
- `timing_plan.md`
- `collaboration_log.md`

**輸出**：`workflow-b-pipeline/rtl/*.v`

1. 模組與 timing_plan Hierarchy 一致
2. Sequential 對應 plan stage
3. port 與 spec_refined 一致
4. 註解引用 Stage ID 或 spec 章節
5. 文件不足則停止並列缺失，勿自行發明架構

**Verilog**：單一 `clk`；預設 `rst_n`；可綜合；檔名=模組名。

---

## 完整 Pipeline

```
spec/ → Agent1 → spec_refined.md → Agent2 → timing_plan.md
     → [協作 ≤3 輪] → ALIGNED → Agent3 → rtl/*.v
```

單步執行時不跳過前置產物。

## 子代理（可選）

大型設計可 Task 子代理跑 Agent1/2；主對話合併 log 後 Agent3。

## 回報

產物路徑、協作輪數、模組列表、殘留 `[ASSUMPTION]`。
