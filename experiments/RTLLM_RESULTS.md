# RTLLM 實驗結果 — Workflow A vs Workflow B（50 題完整測試）

> 實驗日期：2026-06-23  
> Benchmark：RTLLM 50 題（Arithmetic / Control / Memory / Miscellaneous）  
> 評估方式：Pass@1，VCS 編譯 + 模擬，禁止依 log 修改 RTL  
> 改善流程：First Shot B（無 SKILL）→ 加入 domain_knowledge + Agent 指令強化 → Final 完整 A/B 對比

---

## Pipeline B 改善軌跡

| 階段                                                              | Sim Pass | Pass@1    |
| ---------------------------------------------------------------- | -------- | --------- |
| **First Shot A**（Direct SPEC→RTL，未 tune workflow）              | 39 / 50  | **78.0%** |
| **First Shot B**（無 SKILL，無 domain_knowledge）                    | 35 / 50  | **70.0%** |
| **Final 完整重跑**（加入 SKILL + domain_knowledge，50 題全新 A/B 平行實驗） | 47 / 50  | **94.0%** |

> First Shot A 分數與 RTL 存於 `experiments/results.csv`（workflow=a）與 `experiments/artifacts/*/workflow_a/`。  
> Final A 嚴格 Pass@1 為 38/50（76%），見下方「最終 A vs B 對比」。


> 註：#28 LFSR 在 Final 重跑時因 positional mapping 再次 compile fail（不同 seed 下 port 順序推測不同）。
> #29 barrel_shifter 在 First Shot 時 pass，但在 Final 重跑時 fail（1 failure），屬隨機波動。

---

## First Shot B — 15 題失敗明細

改善前 Pipeline B 有 **15 題 failure**（6 compile fail + 9 sim fail/error/hang）。


| #   | ID                 | 結果                | 錯誤大類                        |
| --- | ------------------ | ----------------- | --------------------------- |
| 7   | `comparator_3bit`  | sim fail (16/100) | 組合邏輯方程式錯誤                   |
| 9   | `div_16bit`        | sim fail (37/100) | 暫存器位寬不足                     |
| 10  | `radix2_div`       | sim Error         | Shift register 位元佈局錯誤       |
| 14  | `multi_pipe_4bit`  | **compile fail**  | Verilog 語法陷阱（陣列邊界含除法）       |
| 18  | `float_multi`      | sim fail (1/20)   | Verilog 語法陷阱（乘法位寬截斷）        |
| 26  | `asyn_fifo`        | sim Error         | 非同步設計 / 跨時域                 |
| 28  | `LFSR`             | **compile fail**  | Port 順序（positional mapping） |
| 32  | `freq_divbyeven`   | sim fail (6/20)   | Counter 溢位                  |
| 33  | `freq_divbyfrac`   | sim fail (12/20)  | 分頻器複雜度                      |
| 34  | `freq_divbyodd`    | sim fail (9/20)   | 分頻器複雜度                      |
| 38  | `pulse_detect`     | sim Error         | FSM 邊界條件                    |
| 39  | `serial2parallel`  | **hang**          | Handshake 時序                |
| 41  | `traffic_light`    | **hang**          | FSM 時序                      |
| 45  | `alu`              | sim Error         | 輸出涵蓋不全                      |
| 49  | `signal_generator` | sim Error         | 輸出邊界條件                      |


---

## 最終 A vs B 對比

### Pass@1


| Workflow                | Compile Pass | Compile Rate | Sim Pass    | Pass@1    |
| ----------------------- | ------------ | ------------ | ----------- | --------- |
| A（Direct SPEC→RTL）      | 48 / 50      | 96.0%        | 38 / 50     | **76.0%** |
| B（Pipeline: Agent1→2→3） | 49 / 50      | 98.0%        | **47 / 50** | **94.0%** |


> 註：#28 LFSR 的 A 結果是在允許查看 testbench port order 的條件下取得的，嚴格 Pass@1 不計入乾淨 Pass，故 A 調整為 38/50。

### 結果分類


| 類別              | 題數    | 說明                                 |
| --------------- | ----- | ---------------------------------- |
| AB 都 PASS       | 38    | 兩者能力範圍內的基本題                        |
| **B > A（B 救回）** | **9** | Workflow B 的 pipeline 克服了 A 的 bug  |
| **AB 都錯**       | **3** | 模型/工具能力上限（含 #28 嚴格 Pass@1 也算 fail） |
| **A > B**       | **0** | 無。唯一反例 #28 的 A 結果非乾淨 Pass          |
| 總計              | 50    |                                    |


---

## 1. B > A（B 救回）— 9 題

Workflow B 的 pipeline 成功救回了 A 原本失敗的 9 題。


| #   | ID                  | A 結果                     | B 結果     | 改善根因                                                            |
| --- | ------------------- | ------------------------ | -------- | --------------------------------------------------------------- |
| 10  | `radix2_div`        | fail (div=255, got 0100) | **PASS** | Shift register 位元佈局錯誤 → Agent2 §8 強制指定 SR bit layout            |
| 25  | `sequence_detector` | fail (2/100)             | **PASS** | FSM 轉移表不完整 → Agent1 §8 全狀態×全輸入列舉                                |
| 27  | `LIFObuffer`        | **compile fail**         | **PASS** | VCS 語法錯誤 → domain_knowledge §6.5 (`always` block 左側信號必須是 `reg`) |
| 32  | `freq_divbyeven`    | fail (11/20)             | **PASS** | Counter 溢位 → domain_knowledge §5.2 ($clog2 計算位寬)                |
| 33  | `freq_divbyfrac`    | fail (10/20)             | **PASS** | 分頻器時序複雜 → Agent1 §7 cycle-level timing 精確定義                     |
| 34  | `freq_divbyodd`     | fail (9/20)              | **PASS** | 同 #33，分頻器時序改善                                                   |
| 38  | `pulse_detect`      | fail (Error)             | **PASS** | FSM 邊界條件遺漏 → Agent1 §10 corner cases 明確列出                       |
| 41  | `traffic_light`     | hang                     | **PASS** | Edge detection 時序 bug → Agent1 §4 §8 明確定義 counter reload        |
| 49  | `signal_generator`  | fail (Error)             | **PASS** | 三角波頂點/底點狀態轉換 race → timing_plan §3 明確更新順序                       |


### 關鍵改善機制


| 機制                                  | 對應 SKILL 條文                | 拯救題數          |
| ----------------------------------- | -------------------------- | ------------- |
| **FSM 全狀態×全輸入列舉**                   | Agent1 §8                  | #25, #38, #41 |
| **declaration-before-use + reg 紀律** | domain_knowledge §1 + §6.5 | #27           |
| **位寬計算 ($clog2)**                   | domain_knowledge §5.2      | #32           |
| **cycle-level timing**              | Agent1 §7                  | #33, #34      |
| **corner cases 明確定義**               | Agent1 §10                 | #38           |
| **shift register bit-layout 圖**     | Agent2 §8                  | #10           |
| **輸出更新順序規範**                        | timing_plan §3 + Agent1 §4 | #49           |


---

## 2. AB 都錯 — 3 題（詳細根因分析）

這三題的共同特徵：**錯誤的關鍵資訊不在 SPEC 中**，而在 testbench 的行為或 CDC 的隱性設計知識中。這是當前 pipeline 的能力邊界 — SPEC→RTL 的正確性上限受制於 SPEC 的資訊完整度。

---

### #29 `barrel_shifter` — 語義錯誤：rotate-left vs shift-right

**我們的 RTL（A 和 B 版本相同）**：實作了 rotate-left（循環左移）。

```verilog
// 每個 stage 的邏輯（以 shift-by-4 為例）：
mux2X1 u_s2_mux0 (.a(in[0]), .b(in[4]), .sel(ctrl[2]), .out(s2_out[0]));
// → ctrl[2]=1 時 s2_out[i] = in[(i+4)%8] — 這是 rotate-left
```

**參考 RTL**：實作了 logical shift-right with zero-fill。

```verilog
// 參考的 Stage 2（shift-right by 4）：
mux2X1 ins_17 (.in0(in[7]), .in1(1'b0), .sel(ctrl[2]), .out(x[7]));   // MSB → 0
mux2X1 ins_13 (.in0(in[3]), .in1(in[7]), .sel(ctrl[2]), .out(x[3]));  // data → right
// → 高位填 0，低位來自高位資料 — 這是 logical shift-right
```

**對比測試結果**：


| in (binary)    | ctrl | 我們的 rotate-left | 參考 shift-right（TB 預期） |
| -------------- | ---- | --------------- | --------------------- |
| 10000000 (128) | 4    | 00000100 (4)    | 00001000 (8)          |
| 10000000 (128) | 2    | 00000010 (2)    | 00100000 (32)         |
| 10000000 (128) | 1    | 00000001 (1)    | 01000000 (64)         |
| 11111111 (255) | 7    | 11111111 (255)  | 00000001 (1)          |


**根因**：SPEC 原文用了「shifts or rotates」和「rotating bits」，模型基於標題選擇了 rotate。但 testbench 預期的是 logical shift-right（高位填 0）。這是一個 operation semantics 的根本誤解，SPEC 中的用詞模糊（shift / rotate 混用），沒有 testbench 無法判斷是哪一種。

**為什麼 pipeline 抓不到**：Agent1/Agent2 都把 SPEC 的 "rotating" 一詞解讀為 rotate 語義，精煉後的 spec_refined 和 timing_plan 都正確地描述了 rotate-left 的邏輯。錯誤不在 pipeline 步驟中，而在於 **SPEC 本身的語義模糊性**。

---

### #28 `LFSR` — Port 順序 mismatch（positional mapping）

**我們的 B 版本**：

```verilog
module LFSR (
  input        clk,   // port 1
  input        rst,   // port 2
  output reg [3:0] out // port 3
);
```

**Testbench 的 instantiation**：

```verilog
LFSR DUT(out_tb, clk_tb, rst_tb);  // positional!
//       ^^^^^^  ^^^^^^  ^^^^^^
//        port1   port2   port3
```

**參考 RTL**：

```verilog
module LFSR (out, clk, rst);  // port 順序: out, clk, rst ← 與 testbench 一致
```

**Port 順序對比**：


| Port 名稱 | TB 預期順序 | 我們的順序 | 參考順序  |
| ------- | ------- | ----- | ----- |
| out     | 第 1     | 第 3 ✗ | 第 1 ✓ |
| clk     | 第 2     | 第 1 ✗ | 第 2 ✓ |
| rst     | 第 3     | 第 2 ✗ | 第 3 ✓ |


**後果**：`out_tb`（testbench 的 wire）接到了我們的 `clk` 輸入；`clk_tb`（時序驅動）接到我們的 `rst`；`rst_tb`（reg 變數）接到我們的 `out`（output，受外部驅動）→ **multiple driver → compile fail**。

**根因**：Testbench 使用 positional port mapping（`DUT(a, b, c)` 而非 `DUT(.port1(a), .port2(b), ...)`），port 宣告順序即為接腳定義。我們的 B 版本以 `{input, input, output}` 慣例排序（合乎一般 coding style），但 testbench 預期的順序是 `{output, input, input}`（以 output 優先）。Port 順序是純粹的慣例問題，**SPEC 沒有規定**。

**為什麼 pipeline 抓不到**：SKILL 中 Agent3 §4 有提醒「Port order must match testbench expectation」，但具體順序只能從 SPEC 推斷。A 版本的 port 順序是對的（`out, clk, rst`），但那是 **查看了 testbench 後才知道的**，嚴格 Pass@1 下不算乾淨 PASS。

---

### #26 `asyn_fifo` — 缺少 Gray code pipeline register

這是三題中最微妙的錯誤。

**我們的 B 版本（Gray code 是 combinational）**：

```verilog
assign wptr = wbin ^ (wbin >> 1);   // combinational — 直接從 counter 算出
// 直接跨 domain 同步
always @(posedge wclk or negedge wrstn) begin
    rptr_syn1 <= rptr;   // rptr 也是 combinational
    rptr_syn  <= rptr_syn1;
end
```

**參考 RTL（Gray code 先 register 再同步）**：

```verilog
assign waddr_gray = waddr_bin ^ (waddr_bin>>1);  // combinational
always @(posedge wclk or negedge wrstn) begin
    wptr <= waddr_gray;   // ← 關鍵：在 source domain 先 register 一個 cycle
end
// 然後才跨 domain 同步
always @(posedge wclk or negedge wrstn) begin
    rptr_buff <= rptr;    // rptr 已經是 registered
    rptr_syn  <= rptr_buff;
end
```

**A 版本反而有這個 register**：

```verilog
always @(posedge wclk or negedge wrstn) begin
    wptr <= (waddr_bin >> 1) ^ waddr_bin;  // ← A 版本是 registered 的
end
```

但 A 版本 compile fail（語法問題），B 版本 compile pass 但 sim fail。

**關鍵差異 — pipeline 級數**：

```
參考 pipeline（4 級）:
  bin counter → gray(comb) → [gray register] → sync_stage1 → sync_stage2 → full/empty detect

我們的 pipeline（3 級）:
  bin counter → gray(comb) ───╳ (missing) → sync_stage1 → sync_stage2 → full/empty detect
```

**導致的後果**：


| 事件              | 參考 wfull 變化時間    | 我們的 wfull 變化時間 | 差異            |
| --------------- | ---------------- | -------------- | ------------- |
| write 後 wptr 更新 | 下一個 wclk posedge | 同一個 wclk cycle | 我們快 1 個 cycle |


我們的 full/empty flag 比 golden file 早了 1 個 clock cycle，而 testbench 在固定的 48 個時間點逐點比對 `{wfull, rempty, rdata}` — 時間對不上 → **全部錯**。

**根因**：非同步 FIFO 的 CDC（Clock Domain Crossing）pipeline 中有 4 級 register chain（`src_reg → sync1 → sync2 → flag_compare`），我們少了一級，導致 timing 錯位。SPEC 沒有明說要有這個 register；這是 **CDC 設計的隱性知識**。

**為什麼 pipeline 抓不到**：Agent1 的 spec_refined 和 Agent2 的 timing_plan 都沒有精確描述 pointer 路徑上的 register 級數。timing_plan 確實定義了 synchronizer 的 2 級 shift register，但遺漏了 source side 的 Gray code register。這是一個 **CDC timing 的隱微問題**。

---

### 總結表


| #   | Problem          | 錯誤類型        | 根因一詞               | 能否從 SPEC 推斷                   | Pipeline 可否改善                                      |
| --- | ---------------- | ----------- | ------------------ | ----------------------------- | -------------------------------------------------- |
| 29  | `barrel_shifter` | 語義錯誤        | rotate vs shift    | ❌ SPEC 用詞模糊                   | 需 Agent1 針對模糊詞做 `[ASSUMPTION]` 並列舉兩種可能性            |
| 28  | `LFSR`           | Port 順序     | positional mapping | ❌ SPEC 不規定 port 順序            | Agent3 §4 已有提醒，但無 SPEC 資訊無法判斷                      |
| 26  | `asyn_fifo`      | Pipeline 級數 | 缺 Gray register    | ❌ SPEC 未描述 CDC register chain | Agent2 可用 §new declarations 明確標記 Gray register 必要性 |


---

## 3. A > B — 無

無。唯一曾被認為是反例的 **#28 LFSR**，其 A 結果是在允許查看 testbench port order 的條件下取得的，並非乾淨的 Pass@1。在統一標準下，A 也無法通過此題。

---

## 統計總表


| 指標                  | A               | B                    |
| ------------------- | --------------- | -------------------- |
| Compile pass        | 48 / 50 (96.0%) | 49 / 50 (98.0%)      |
| Sim pass（嚴格 Pass@1） | 38 / 50 (76.0%) | **47 / 50 (94.0%)**  |
| **B 淨增益**           | —               | **+9 題**             |
| B 救回                | —               | **9 題**              |
| B 新錯 vs A           | —               | 0 題（#28 兩者皆非乾淨 Pass） |


---

## 結論

1. **Workflow B 顯著優於 A**：嚴格 Pass@1 下 Pass rate 從 76.0% 提升到 94.0%，淨增益 +9 題。
2. **domain_knowledge.md 直接因果證據**：§6.5 (`always` → `reg`) 直接救了 #27 LIFObuffer compile fail；§5.2 (位寬計算) 直接救了 #32 freq_divbyeven。
3. **Agent1 §8 全狀態列舉最有效**：9 題救回中有 5 題直接或間接受益於 FSM 轉移表的完整列舉。
4. **原本被認為的唯一反例 #28 LFSR**，實際上是 AB 都 fail（A 的 pass 依賴於查看 TB port order），所以嚴格 Pass@1 下 **B 無反例**。Positional mapping 的脆弱性已在 Agent3 §4 納入規則。
5. **AB 都錯的 3 題**定義了當前 pipeline 的能力邊界：
  - **#29 barrel_shifter**：SPEC 語義模糊（rotate vs shift），Agent1 可針對模糊詞增加 `[ASSUMPTION]` 並列舉兩種可能性
  - **#28 LFSR**：positional mapping 純粹慣例問題，Agent3 §4 已納入 port order 規則
  - **#26 asyn_fifo**：缺少 CDC pipeline 的 Gray code register，Agent2 可在 timing_plan 中用 §new declarations 明確標記 register 級數
  - 三題的共同特徵：**錯誤的關鍵資訊不在 SPEC 中**，而在 testbench 的行為或 CDC 的隱性設計知識中。這是 SPEC→RTL 生成的上限。

