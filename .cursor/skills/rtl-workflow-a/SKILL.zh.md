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

可選補充：`SPEC 路徑為 spec/design.spec.txt`（或實際檔名）。

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

SPEC 路徑、`.v` 與模組列表、假設。  
**不要**執行 VCS；評測由使用者在生成後於 RTLLM 目錄進行。
