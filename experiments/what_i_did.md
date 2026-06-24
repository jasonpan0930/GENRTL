# Workflow B 改善記錄 — 從 50 題大規模驗證中歸納

## 背景

對 Workflow A 和 Workflow B 各跑了 50 題 RTLLM benchmark，從 `results.csv` 的 compile/sim 結果統計出兩種 workflow 的失敗題，再逐一打開 RTL 原始碼、SPEC、testbench 分析根因。

## 發現的 AI 生 .v 問題

總計找出 **8 類典型問題**，對應到 Pipeline B 的不同階段：

### 1. Port 順序與 testbench 不匹配
- **案例**：#28 LFSR (Workflow B compile fail)
- **原因**：Testbench 用 `LFSR DUT(out_tb,clk_tb,rst_tb)` — **positional mapping**，但 B 版宣告 port 為 `(clk, rst, out)`，順序不符導致 `rst_tb`（reg，外部驅動）連到 output port `out`，產生 **multiple driver compile error**。
- **發生率**：testbench 若用 positional mapping，AI 重新排序 port 就會中招。

### 2. 組合邏輯方程式錯誤
- **案例**：#7 comparator_3bit (Workflow B, 16/100 failures)
- **原因**：`gt1` 和 `gt0` 寫成 `~A[2] & ~B[2]`（檢查兩者皆 0），實際應寫 `~(A[2] ^ B[2])`（檢查相等）。這個位元級邏輯方程對 AI 是常見盲點。

### 3. 內部暫存器位寬不足
- **案例**：#9 div_16bit (B, 37/100)、#32~34 freq_div (A+B)
- **原因**：`temp_r` 宣告 `reg [7:0]` 但 16-bit ÷ 8-bit 除法中部分餘數可達 16 bits；`cnt` 寫死 `reg [3:0]` 但 `NUM_DIV` 參數可能超過 15。Counter overflow 導致 FSM 行為異常。

### 4. Shift register 位元佈局錯誤
- **案例**：#10 radix2_div (A+B 都錯)
- **原因**：Workflow A 的位移操作有 gap bit 未正確處理；B 版的 9-bit SR 取出 quotient bit 時只取了 1 個 bit，其餘 7 個 quotient bits 全部遺失。兩者都是因為沒有精確定義 SR 內部位元分配到哪去了。

### 5. Handshake 時序死鎖
- **案例**：#39 serial2parallel (B, hang)、#41 traffic_light (A+B, hang)
- **原因**：Testbench 用 `while(dout_valid == 0)` 等待有效訊號，但 RTL 的 valid 訊號只在特定 cycle 短暫出現，可能因 event ordering 被錯過。Traffic light 的 counter reload edge-detection (`!red_o && p_red`) 永遠不會成立，counter wrap 到 255 卡死。

### 6. Flag / 多輸出涵蓋不全
- **案例**：#45 alu (B, Error)
- **原因**：`overflow` flag 只檢查 `ADD` 和 `SUB` 的 overflow，其他 opcode（`ADDU`、`SUBU` 等）未處理。Testbench 預期每個 opcode 的所有 flag 都有定義。

### 7. 邊界 / corner case 未處理
- **案例**：#38 pulse_detect (A+B, Error)、#49 signal_generator (A+B, Error)
- **原因**：Pulse detect 的連續快速 toggle 觸發未明確定義的狀態行為；Signal generator 在三角波頂點/底點的轉換時序有 X 或 glitch。

### 8. 參數化陣列邊界使用除法
- **案例**：#14 multi_pipe_4bit (B, compile fail)
- **原因**：`reg [2*size-1:0] sum1 [0:size/2-1]` — unpacked array 維度含除法運算，部分 VCS 版本無法正確推導邊界。

## 所做改善

### 修改 `SKILL.en.md`
在 Pipeline 的三個 Agent 階段各追加了指令：

| 階段 | 新增項目 | 對應改善 |
|------|---------|---------|
| Agent1 §7 | Cycle-level handshake 時序規範 | 改善 5 |
| Agent1 §8 | FSM 全狀態全輸入列舉 | 改善 5 |
| Agent1 §9 | Multi-output per-opcode 列舉表 | 改善 6 |
| Agent1 §10 | Explicit corner-case section | 改善 7 |
| Agent2 §7 | 組合邏輯寫 exact Boolean equation | 改善 2 |
| Agent2 §8 | Shift register bit-layout 圖 | 改善 4 |
| Agent3 §4 | Port order 必須 match testbench | 改善 1 |
| Agent3 §5 | 子模組用 named port mapping | 改善 1 |

### 修改 `domain_knowledge.en.md` + `domain_knowledge.md`
新增兩個完整章節：

| 章節 | 內容 | 對應改善 |
|------|------|---------|
| §5 Width discipline | Register width、parameterized counter ($clog2)、remainder storage | 改善 3 |
| §6 Synthesis pitfalls | Unpacked array computed bounds、positional mapping、counter termination | 改善 8 |

### 追加 §6.4 (re-run 後發現)
- **問題**：#18 float_multi (B, 1/20 failures，改善前後皆同)
- **根因**：Verilog 乘法 `a_mantissa * b_mantissa`（24-bit × 24-bit）的結果寬度取**最大運算元寬度**（24 bits）而非完整 48-bit 乘積。`product <= {2'b00, a_mantissa * b_mantissa}` 只拿到低 24 bits，導致 normalization 取到接近零的值，輸出 `0x3D800001`（≈0.0625）而非預期 `0x3DB85EC0`（≈0.09）。
- **修正**：domain_knowledge §6.4 加入乘法位寬陷阱規則，要求先 zero-extend 運算元再相乘。

## 實際驗證結果 (改善後 SKILL 重跑 15 題)

用改善後的 SKILL（不加任何額外 hint）重新產生 15 題 pipeline B 的 RTL → archive → eval，結果：

| 指標 | 改善前 | 改善後 |
|-----|-------|-------|
| compile pass | 13/15 | **15/15** |
| sim pass | 9/15 | **14/15** |
| 唯一殘留失敗 | - | #18 float_multi (1/20, Verilog 乘法位寬陷阱) |

上述 8 項改善全數套入後，預估 Workflow B Pass@1 可從 **~70% 提升到 ~85–90%**。

## VerilogEval 實驗中發現的新問題

### 9. `always_comb` 賦值信號誤宣告為 `wire`（VCS IBLHS-NT）
- **案例**：VerilogEval #140 `fsm_hdlc` (Workflow B, compile fail: 10 errors)
- **錯誤訊息**：`Error-[IBLHS-NT] Illegal behavioral left hand side`
- **根因**：FSM 的 `nstate` 信號被宣告為 `wire`，但 `always_comb` block 中對它賦值。Verilog 規定 `always` block 左側被賦值必須是 `reg`（或 `logic`），`wire` 只能由 `assign` 或 port 驅動。
- **修正**：將 `wire [3:0] nstate` 改為 `reg [3:0] nstate`
- **預防**：於 `domain_knowledge.md` §6.5 新增「always 內被賦值信號必須是 reg」規則，含錯誤/正確範例，要求 Agent3 在寫 RTL 前檢查每個 `always` block 左側信號的宣告類型。
