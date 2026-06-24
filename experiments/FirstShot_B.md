# Pipeline B 第一次執行錯誤分析 (Failed Cases in First Shot)

## 失敗題目總覽

改善前，Pipeline B 50 題中共有 **15 題 failure** (6 題 compile fail + 9 題 sim fail/error/hang)。

---

## 各題錯誤原因

### 1. Port 順序不符 testbench

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 28 | LFSR | **compile fail** | Testbench 用 positional mapping `LFSR DUT(out_tb,clk_tb,rst_tb)`，但 RTL 宣告 `(clk, rst, out)`，順序不符導致 `rst_tb`（reg，外部驅動）連到 output port `out` → multiple driver。 |

---

### 2. 暫存器位寬不足 / Counter 溢位

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 9 | div_16bit | sim fail (37/100) | `temp_r` 宣告 `reg [7:0]`，但 16-bit÷8-bit 除法的部分餘數可達 16 bits，迭代中 MSB 被截斷使商數和餘數皆不正確。 |
| 32 | freq_divbyeven | sim fail (6/20) | `half_limit = (NUM_DIV>>1) - 4'd1` 用 4-bit 減法，部分參數下 limit 計算錯誤；且 `reg [3:0] cnt` 對 NUM_DIV>15 會溢位。 |

---

### 3. 組合邏輯方程式錯誤

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 7 | comparator_3bit | sim fail (16/100) | `gt1`/`gt0` 寫成 `~A[2] & ~B[2]`（檢查兩者皆 0），應為 `~(A[2] ^ B[2])`（檢查相等）。MSB 為 1 時比較結果錯誤。 |

---

### 4. Verilog 語法陷阱

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 14 | multi_pipe_4bit | **compile fail** | `reg [2*size-1:0] sum1 [0:size/2-1]` — unpacked array 維度含除法運算，VCS 無法正確推導邊界。 |
| 18 | float_multi | sim fail (1/20) | Verilog 中 `a_mantissa * b_mantissa`（24-bit×24-bit）結果寬度取最大運算元寬度（24 bits）而非 48-bit 完整乘積。`product <= {2'b00, a_mantissa * b_mantissa}` 只拿到低 24 bits → normalization 取到接近零的值 → 輸出 `0x3D800001`（≈0.0625）而非 `0x3DB85EC0`（≈0.09）。 |

---

### 5. Shift register 位元佈局錯誤

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 10 | radix2_div | sim Error | B 版的 9-bit SR 中 `raw_quotient = {SR[0], 7'b0}` 只取 1 個 quotient bit 放到 MSB，其餘 7 個 quotient bits 全部遺失。`{next_partial_rem, SR[0], quotient_bit}` 拼出 10-bit 賦給 9-bit SR，MSB 被截斷。 |

---

### 6. 非同步設計 / 跨時域錯誤

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 26 | asyn_fifo | sim Error | Gray code 同步器產生的 `wfull`/`rempty` 與 testbench 預期行為不符，讀寫指標不同步或資料不一致觸發 testbench Error。 |

---

### 7. 分頻器複雜度過高

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 33 | freq_divbyfrac | sim fail (12/20) | 3.5x 分頻需走 7 個 cycle、4+3 不均等週期、OR 兩個偏移半週期的中間時脈，duty cycle / phase alignment 易出錯。 |
| 34 | freq_divbyodd | sim fail (9/20) | 兩路 OR 的中間時脈與 testbench 預期邊緣位置不符。 |

---

### 8. FSM / Handshake 時序錯誤

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 38 | pulse_detect | sim Error | 010 脈衝檢測在連續快速 toggle (如 01010) 下 undefined 行為，狀態判斷出錯。 |
| 39 | serial2parallel | **hang** | TB 用 `while(dout_valid == 0) #5` 等待，但 RTL 的 `dout_valid` 只在 `cnt==7` 時 pulse 一個 cycle，event ordering 錯過即無窮等待。 |
| 41 | traffic_light | **hang** | Counter reload 用 edge-detection `!red_o && p_red`，但 `red_o` 和 `p_red` 差一個 cycle，條件永遠為 false → counter wrap 到 255 FSM 卡死。 |

---

### 9. 輸出涵蓋不全 / 邊界條件

| # | 題目 | 結果 | 根因 |
|---|------|------|------|
| 45 | alu | sim Error | `overflow` flag 只檢查 `ADD`/`SUB`，未處理其他 opcode → testbench 檢查時觸發 Error。 |
| 49 | signal_generator | sim Error | 三角波在頂點 (`wave==31`) 和底點 (`wave==0`) 轉換時 `state` 與 `wave` 更新順序可能產生 X 或 glitch。 |

---

## 錯誤統計匯總

| 錯誤大類 | 數量 | 題號 |
|---------|------|------|
| Port 順序 (positional mapping) | 1 | #28 |
| 暫存器位寬不足 / counter 溢位 | 2 | #9, #32 |
| 組合邏輯方程式錯誤 | 1 | #7 |
| Verilog 語法陷阱 (乘法寬度 / 陣列邊界) | 2 | #14, #18 |
| Shift register 位元佈局錯誤 | 1 | #10 |
| 非同步設計 / 跨時域 | 1 | #26 |
| 分頻器複雜度 | 2 | #33, #34 |
| FSM/handshake 時序 | 3 | #38, #39, #41 |
| 輸出涵蓋不全 / 邊界條件 | 2 | #45, #49 |
| **合計** | **15** | |

---

## 錯誤種類分布（依改善前後結果）

改善前：compile pass 44/50 (88%), sim pass 35/50 (70%)，Pipeline B 共 15 題 failure。

改善後（SKILL 加入 domain knowledge + Agent 指令強化）：重跑全部 15 題，14/15 pass → sim pass 49/50 (98%)。
唯一殘留：**#18 float_multi**（1/20 failures，Verilog 乘法位寬陷阱）。
