# Domain knowledge — Workflow B RTL 規範

本檔為 **Workflow B 全階段** 共用的領域規範（不隨單次 `prep_problem` 清除）。  
Agent1／2 規劃時須遵守；**Agent3 寫 Verilog 時必讀且必守**。

新增規範請寫在本檔，勿散落於各次 chat。

---

## 1. 變數／信號宣告順序（必守）

**任何信號、變數必須先宣告再使用。** 禁止在宣告之前引用名稱（含 `assign`、`always`、port map、例化連線）。

### 1.1 模組內建議順序

```verilog
module foo #(
    parameter ...
) (
    input  wire ...,
    output reg  ...
);
    // 1) 內部 wire / reg / integer（本模組所有內部信號先宣告完）
    wire ...;
    reg  ...;

    // 2) assign（僅使用已宣告信號）
    assign ... = ...;

    // 3) always / generate
    always @(posedge clk or negedge rst_n) begin
        ...
    end
endmodule
```

### 1.2 `always` 區塊內

- 區塊開頭先宣告該區塊用到的 `integer`、`reg` 等（若需區域變數）。
- 同一區塊內**不得**在宣告列之前使用該名稱。

### 1.3 常見錯誤（禁止）

```verilog
assign sum = a + b;   // BAD: a, b 尚未宣告
wire [7:0] a, b;
```

```verilog
always @(*) begin
    y = f(x);           // BAD: x 尚未宣告
    reg x;
end
```

### 1.4 子模組例化

- 例化前，連到子模組的 **wire/reg 必須已宣告**。
- 例化區塊建議放在內部信號宣告之後、`assign`／`always` 之前或依邏輯分組，但**仍須**滿足「先宣告後使用」。

### 1.5 Agent2 `timing_plan.md`

- 列出 stage 信號時，註明該信號為 **新宣告** 或 **來自上一 stage**；避免 Agent3 在未宣告名稱上接線。

---

## 2. Reset 與時脈（摘要）

細節以 `spec_refined.md` §Reset 為準；此處僅提醒：

- **禁止**擅自將 `rst` 改成 `rst_n` 或反之（名稱以原始 SPEC／`spec_refined` 為準）。
- 單一 `clk`；`always` 的 reset 邊緣與極性須與 `spec_refined` 一致。

---

## 3. 可綜合與檔名

- 以 **Verilog-2001** 可綜合子集為目標；避免不可綜合語法（如 `#delay` 於 RTL）。
- 檔名 = 模組名 = `run_context.json` 的 `top_module`（除非 `spec_refined` 另有說明）。

---

## 4. 擴充區

（以下由專案維護者追加慣例。）

<!-- 例：握手協定、位寬對齊、one-hot FSM 編碼偏好… -->

---

## 5. 位寬紀律（必守）

### 5.1 暫存器寬度 vs 儲存值
每個暫存器宣告的寬度必須足夠容納：
- 它可能存放的**最大值**（考慮參數化）。
- 算術／移位運算中的所有中間結果。

若暫存器存放 N-bit 和 M-bit 值的和，寬度必須是 `max(N, M) + 1`。
若存放移位鏈，寬度必須涵蓋所有移位後的位元（左移增加位元，右移勿過早截斷）。

### 5.2 參數化計數器寬度
對參數化模組（`#(parameter N = ...)`）中的計數器：

```verilog
// 正確：始終計算最壞情況寬度
localparam C_W = $clog2(N+1);  // 夠容納 0..N
reg [C_W-1:0] cnt;
```

**禁止**寫死 `reg [3:0] cnt`（當 N 可能超過 15 時）。Agent1 必須說明各參數的假定範圍；Agent2 必須依最大值設定計數器寬度。

### 5.3 餘數／中間儲存寬度
進行除法或乘法時，提取被除數高位元的「暫存餘數」暫存器必須夠寬，以容納**每次迭代中的部分餘數**——不僅是最終餘數。對 N-bit ÷ M-bit 除法器（N > M），部分餘數可達 N bits；請相應宣告保留暫存器。

---

## 6. 綜合與模擬陷阱

### 6.1 含計算式的 unpacked array
避免在 unpacked array 維度邊界中使用算術運算（`[0:size/2-1]`）。部分工具會拒絕陣列邊界中的除法。請改用 `localparam`：

```verilog
// 避免：
reg [7:0] arr [0:size/2-1];

// 建議：
localparam ARR_DEPTH = size / 2;
reg [7:0] arr [0:ARR_DEPTH-1];
```

### 6.2 錯誤的 port 順序導致多驅動
若 testbench 使用**位置對應**（positional mapping），你的 port 宣告順序**就是**接腳定義。順序不符會將錯誤信號接到錯誤 port，可能產生 multiple driver（X/Z 衝突）或傳遞錯誤值。不確定時，請**嚴格遵循原始 SPEC 的 port 順序**。

### 6.3 計數器終止
計數器到達上限後必須停止或乾淨地繞回。若計數器繼續遞增後繞回（例如 `4'd15 → 4'd0`），會導致 FSM 行為異常。務必包含明確的 `if (cnt == LIMIT) cnt <= 0` 分支；不要依賴不等式來捕捉繞回邊界。

### 6.4 Verilog 乘法結果位寬（關鍵陷阱）
在 Verilog 中，`A * B` 的結果寬度取決於**最大運算元的寬度**，**不是**完整乘積的寬度。這是一個常見陷阱，會無聲地截斷結果。

```verilog
reg [23:0] a_mantissa, b_mantissa;
reg [49:0] product;

// 錯誤 — product 只拿到 24-bit 截斷結果：
product <= {2'b00, a_mantissa * b_mantissa};
// a_mantissa * b_mantissa 只取 24 bits（最大運算元寬度），
// 因此 product 只收到 48-bit 乘積的低 24 bits。

// 正確 — 乘法前明確擴展運算元：
product <= {24'd0, a_mantissa} * {24'd0, b_mantissa};
// 每個運算元變成 48-bit，所以乘法結果是完整的 48 bits。
```

**基本原則**：當賦值給 N-bit 乘積暫存器時，確保 `*` 表達式中每個運算元在乘法前至少是 N bits——明確地 zero-extend 或 sign-extend。不要依賴左側目標寬度來控制中間結果的位寬。
