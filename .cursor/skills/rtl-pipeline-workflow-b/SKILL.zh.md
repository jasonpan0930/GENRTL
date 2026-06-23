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
分階段時使用者指明「僅 Agent1／Agent2／Agent3」。

### 題號簡寫

可說 **`RTLLM #6`** 或 **`adder_pipe_64bit`**。
也可說 **`VerilogEval #1`** 或 **`zero`**；此時 top_module 固定為 `TopModule`。

#### 共通前置

0. **任務開始時**先執行：`source ~/source.sh`

#### RTLLM 流程

1. 若使用者給 `RTLLM #N` 或 id，**Agent 執行** `./scripts/prep_problem.sh <N|id> --full-clean`
2. 讀 run context 與 SPEC；輸出 `workflow-b-pipeline/rtl/<top_module>.v`
3. RTL 完成後 **Agent 執行** `./scripts/archive_run.sh b`
4. 含評測 / `with eval` 時：**執行** `./scripts/run_vcs.sh b`；僅回報結果

#### VerilogEval 流程

1. 若使用者給 `VerilogEval #N` 或 id，**Agent 執行** `./scripts/prep_ve_problem.sh <N|id> --full-clean`
2. 讀 run context 與 SPEC；輸出 `workflow-b-pipeline/rtl/TopModule.v`（top_module 固定為 `TopModule`）
3. RTL 完成後 **Agent 執行** `./scripts/archive_ve_run.sh b`
4. 含評測 / `with eval` 時：**執行** `./scripts/run_ve_sim.sh b <N>`；僅回報結果

#### 通用規則

**Pass@1 禁止**依 sim log 改 RTL

可選：`SPEC: spec/design.spec.txt` · `with eval`

## SPEC 讀取

1. `spec/design.spec.md`
2. `spec/design.spec.txt`
3. `spec/` 內唯一 `.md` / `.txt`（排除 `*.example`）

## 禁止讀取（Pass@1）

勿讀 `RTLLM/`、`verified_*.v`、`testbench.v`、`_chatgpt35/`、`_chatgpt4/`。缺 port／行為僅用 `[ASSUMPTION]` 或停止。

## 領域規範（domain knowledge）

- 路徑：`workflow-b-pipeline/domain_knowledge.md`（英文：`domain_knowledge.en.md`）
- **Agent1 / Agent2 / Agent3 開始工作前須讀取**
- 新慣例（宣告順序、編碼風格等）**只寫入此檔**，再於 skill 內引用
- **Agent3 必守 §1：所有變數／信號先宣告再使用**

---

## Agent1 — SPEC 精煉

**輸出**：`workflow-b-pipeline/spec_refined.md`

1. 保留原始需求
2. 補全 port、位寬、clock/reset、協定、邊界
3. **Reset 信號（必寫，依原始 SPEC，勿擅自改名）**
   - 在 **§2 介面** 與 **§4 時序** 各寫一小節 **Reset**
   - **port 名稱** 必須與原始 SPEC 一致：`rst` 就寫 `rst`，`rst_n` 就寫 `rst_n`；**禁止**把 `rst` 改成 `rst_n` 或反之
   - 明確寫清：**極性**（active-high / active-low）、**同步/非同步**、**釋放/有效時**各 register 初值
   - 若原始 SPEC 只寫 `reset` 未標極性：在 `[ASSUMPTION]` 說明依據原文用詞，**仍保留原文 port 名**
   - 加一條可驗證句，例如：「`always @(posedge clk or negedge rst_n)` 僅當 spec 明定 `rst_n` active-low」
4. 模糊句改為可驗證條目（若…則…）
5. 章節 **假設與決議**：`[ASSUMPTION]`
6. **與原始 SPEC 差異**
7. **待 Agent2 確認**
8. **Cycle-level 握手時序（每組 valid/ready 必寫）**
   對每組握手介面（`opn_valid`/`res_ready`、`din_valid`/`dout_valid` 等），精確規範：
   - 發送端何時 assert `*_valid`（哪個 cycle、相對於何事件）
   - `*_valid` 持續多久（單 cycle？或保持直到 `*_ready` 回傳？）
   - 接收端何時 assert/deassert `*_ready`
   - 同一 cycle 兩者同時 assert 的行為
   - **避免死鎖**：確保沒有 `valid` 等 `ready`、同時 `ready` 等 `valid` 的循環依賴

9. **FSM 完整列舉（每個 state × 每個 input）**
   列出完整轉移表：對每個 state 列舉所有 input 組合，寫明 **下一狀態 + 各輸出值**。
   必須含 **default 子句** 處理無效狀態編碼（例如回到 IDLE）。

10. **每個 opcode 的所有輸出旗標**
    當模組有多個狀態旗標（zero, carry, negative, overflow, flag）與控制 opcode：
    - 對 **每個 opcode**，寫明 **每個旗標** 的輸出值
    - **不得**把任何旗標標為 don't care 或留空——testbench 可能會檢查
    - 若某 opcode 下某旗標真的無定義，寫明安全預設（0 / 1'bz / 保持前一值）

    範例表格：

    | opcode | r       | zero | carry | negative | overflow | flag |
    |--------|---------|------|-------|----------|----------|------|
    | ADD    | a + b   | ...  | ...   | ...      | ...      | 1'bz |
    | SUB    | a - b   | ...  | ...   | ...      | ...      | 1'bz |

11. **邊界狀況專區**
    新增獨立 **§邊界狀況（Corner cases）** 小節：
    - 計數器：最小值、最大值、繞回（wrap-around）行為
    - FSM：無效／保留狀態編碼的行為
    - 算術：溢位、下溢、除以零、NaN/Inf
    - 邊緣偵測：連續快速 toggle、遺漏邊緣、同時雙緣
    - 時序電路：reset 在 clock edge 附近 assert/deassert 的時序

**禁止**：Verilog；完整 timing_plan（可寫介面時序約束）。

---

## Agent2 — 時序與結構

**輸入**：`spec_refined.md`（可對照 `spec/`，不改原始檔）

**輸出**：`workflow-b-pipeline/timing_plan.md`（格式見 [reference.zh.md](reference.zh.md)）

1. Stage 0, 1, 2…
2. 每 stage：`Combinational` / `Sequential` / `Mixed`
3. 跨 stage 信號：名、寬、是否註冊、握手
4. Sequential：clock edge、reset（**信號名與極性與 spec_refined §Reset 一致，勿改用 rst_n 慣例覆蓋 rst**）
5. 頂層 FSM（若有）
6. 新信號標註是否為 **新宣告**（對齊 `domain_knowledge.md` §1.5）
7. **組合邏輯信號：寫出精確的 Boolean／邏輯方程式**
   對每個 combinational output，用**明確的邏輯運算**描述，不可只用「比較結果」等模糊字眼：

   - 好：`A_greater = (A[2] > B[2]) OR (A[2]==B[2] AND A[1]>B[1]) OR ...`
   - 壞：`A_greater 在 A > B 時為 high`

   這可防止 Agent3 在位元級方程式中引入隱微的邏輯錯誤。

8. **Shift register 位元佈局圖（除法／乘法必寫）**
   當設計中的 shift register 持有複合狀態（例如部分餘數 + 商數位元），**畫出精確的位元編排**：

   ```text
   SR = [remainder(8 bits)] [gap?1] [accumulated quotient(7 bits)]
         bit 15..8          bit 7    bit 6..0
   ```

   每次迭代需說明：
   - 哪些位元用於試除／部分積計算
   - 新的 quotient bit 插入哪個位置
   - carry / underflow 如何決定下一拍 SR 值

   若沒有此圖，Agent3 會猜測位元佈局，容易出錯。

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
- `workflow-b-pipeline/domain_knowledge.md`

**輸出**：`workflow-b-pipeline/rtl/*.v`

1. 模組與 timing_plan Hierarchy 一致
2. Sequential 對應 plan stage
3. port 與 spec_refined 一致（**含 reset port 名：rst / rst_n 不得擅自對調**）
4. **Port 順序必須與 testbench 對齊**：部分 testbench 使用 **positional port mapping**（例：`DUT(a, b, clk)` 不含 `.port()`）。重排 port 順序會改變實際接腳。必須**嚴格遵循原始 SPEC 的 port 宣告順序**；不可依字母、方向排列。若 spec_refined 新增 port，附加在原有 port 之後，不可重排原有 port。
5. **子模組例化一律用 named port mapping**：`.port_name(signal)`，禁止 positional。
6. **遵守 domain_knowledge §1：內部 wire/reg 先宣告再 assign/always/例化；模組順序見該檔**
7. 註解引用 Stage ID 或 spec 章節
8. 文件不足則停止並列缺失，勿自行發明架構

**Verilog**：單一 `clk`；**reset 依 spec_refined**（名稱、極性、同步行為）；勿預設改成 `rst_n`；可綜合；檔名=模組名。

**子模組放在同一個檔案**：若設計含多個 module，全都寫在同一個 `<top_module>.v` 內。
> 註：正常設計應分開檔案管理，但目前 testbench 只會讀一個 `.v`（`${TEST_DESIGN}.v`），因此請將所有 module 寫在同一檔案中。頂層 module 放最上面。

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
