# Domain knowledge — Workflow B RTL conventions

Shared **Workflow B** rules (not removed by `prep_problem`).  
Agent1/2 must follow when planning; **Agent3 must read and obey** before writing Verilog.

Add new rules here; do not scatter them across chats.

---

## 1. Declare before use (mandatory)

**Every signal or variable must be declared before it is referenced** in `assign`, `always`, instantiation, or port connections.

### 1.1 Recommended module order

1. `parameter` / port list  
2. Internal `wire` / `reg` / `integer` declarations (all locals first)  
3. `assign`  
4. `always` / `generate`  
5. Submodule instantiations (only after nets they drive are declared)

### 1.2 Inside `always`

- Put block-local `integer` / `reg` declarations at the **top** of the block.  
- Never use a name above its declaration in the same block.

### 1.3 Submodule instances

- Every net connected to a child module must already be declared in the parent.

### 1.4 Agent2 `timing_plan.md`

- Mark each signal as **new declaration** or **from previous stage** so Agent3 does not wire undeclared names.

---

## 2. Reset and clock (summary)

Follow `spec_refined.md` §Reset. Do not rename `rst` ↔ `rst_n`. Single `clk`.

---

## 3. Synthesis and file naming

- Verilog-2001 synthesizable subset.  
- File name = module name = `top_module` from run context unless `spec_refined` says otherwise.

---

## 4. Extensions

(Project-specific conventions go below.)

---

## 5. Width discipline (mandatory)

### 5.1 Register width vs held values
Every register's declared width must be sufficient for:
- The **maximum value** it can ever hold (account for parameterization).
- All intermediate results in arithmetic / shift operations.

If a register holds a sum of N-bit and M-bit values, its width must be
`max(N, M) + 1`. If it holds a shift chain, its width must cover all shifted
bits (left shift adds bits, right shift does not truncate prematurely).

### 5.2 Parameterized counter width
For counters in parameterized modules (`#(parameter N = ...)`):

```verilog
// CORRECT: always compute worst-case width
localparam C_W = $clog2(N+1);  // enough for 0..N
reg [C_W-1:0] cnt;
```

Do NOT hardcode `reg [3:0] cnt` when N can exceed 15. Agent1 must state the
assumed range of each parameter; Agent2 must size counters to fit the maximum.

### 5.3 Remainder / intermediate storage width
When extracting higher bits of an operand for division or multiplication,
the temporary remainder register must be as wide as the **partial remainder**
at every iteration — not just the final remainder. For an N-bit ÷ M-bit divider
(N > M), the partial remainder can reach N bits; declare the hold register
accordingly.

---

## 6. Synthesis and simulation pitfalls

### 6.1 Unpacked arrays with computed bounds
Avoid unpacked array declarations where the dimension bound contains
arithmetic (`[0:size/2-1]`). Some tools reject division in array bounds.
Prefer a `localparam`:

```verilog
// AVOID:
reg [7:0] arr [0:size/2-1];

// PREFER:
localparam ARR_DEPTH = size / 2;
reg [7:0] arr [0:ARR_DEPTH-1];
```

### 6.2 Multiple drivers from incorrect port order
If a testbench uses **positional** port mapping, your port declaration order
**is** the pinout. A mismatch sends the wrong signal to the wrong port,
which can create multiple drivers (X/Z contention) or pass incorrect values.
When in doubt, preserve the original SPEC's port order exactly.

### 6.3 Counter termination
A counter that reaches its limit must either stop or wrap cleanly. A counter
that continues past its valid range and wraps (e.g., `4'd15 → 4'd0`) causes
erratic FSM behavior. Always include a clear `if (cnt == LIMIT) cnt <= 0`
branch; never rely on inequality to catch the wrap boundary.

### 6.4 Verilog multiplication result width (critical)
In Verilog, the width of `A * B` is determined by the **widest operand**,
**not** the full product width. This is a common pitfall that silently
truncates the result.

```verilog
reg [23:0] a_mantissa, b_mantissa;
reg [49:0] product;

// WRONG — product gets only 24-bit truncated result:
product <= {2'b00, a_mantissa * b_mantissa};
// a_mantissa * b_mantissa is 24-bit wide (max operand width),
// so product only receives the low 24 bits of the 48-bit product.

// CORRECT — extend operands before multiplication:
product <= {24'd0, a_mantissa} * {24'd0, b_mantissa};
// Each operand becomes 48-bit, so the multiplication is 48-bit wide.
```

**Rule of thumb**: when assigning to an N-bit product register, ensure every
operand in the `*` expression is at least N bits wide before the multiplication
— zero-extend or sign-extend explicitly. Do not rely on the LHS target width
to control the intermediate result width.

### 6.5 Signals assigned inside `always` must be `reg` (critical trap)

Any signal that appears on the **left-hand side** of an assignment inside an
`always` block (`always @(*)`, `always_comb`, `always_ff`) **must be declared
as `reg`** (or `logic` in SystemVerilog), **not `wire`**. VCS will report
`Error-[IBLHS-NT] Illegal behavioral left hand side`.

This is a hard rule of Verilog — `wire` can only be driven by `assign` or
port connections, never by procedural assignments inside `always`.

```verilog
// WRONG — nstate is a wire, cannot be assigned in always_comb
wire [3:0] nstate;
always_comb begin
    case (state)
        IDLE: nstate = S1;   // ← VCS: IBLHS-NT error
        ...
    endcase
end

// CORRECT — nstate declared as reg
reg [3:0] nstate;
always_comb begin
    case (state)
        IDLE: nstate = S1;   // OK
        ...
    endcase
end
```

**Common signals affected**: FSM next-state (`nstate` / `next_state`),
combinational outputs computed in `always_comb`, intermediate variables inside
`always @(*)`.

**Agent3 must verify before writing RTL**: every signal on the left-hand side
of an `always` block is declared as `reg` in the module declaration area.
