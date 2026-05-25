# 工作進度與工作站交接 | Workstation Handoff

**最後更新**：2026-05-25  
**專案路徑（本機）**：`~/final_genrtl/myProject_GENRTL`  
**Git remote**：`git@github.com:jasonpan0930/GENRTL.git`（branch `main`）  
**建議本次 commit 訊息**：`Add Workflow A skill, Pass@1 rules, cursorignore, docs`

---

## 1. 專題目標（已確認）

比較兩種 **自然語言 SPEC → Verilog RTL** 的 Cursor Agent 流程：

| 代號 | 名稱 | 流程 |
|------|------|------|
| **Workflow A** | 直接生成 | 讀 `spec/` → 寫 `workflow-a-direct/rtl/*.v` |
| **Workflow B** | 多階段 pipeline | Agent1 精煉 SPEC → Agent2 時序/結構 →（協作 ≤3 輪）→ Agent3 RTL |

**計畫中的 benchmark**：RTLLM v2.0 + 工作站 **VCS**（尚未整合進 repo，見 §5）。

---

## 2. 已完成 ✅

### 2.1 專案骨架（48+ 文件，已 push 骨架至 GitHub）

- 雙 workflow 輸出目錄約定
- `spec/` 輸入（支援 `.md` / `.txt`，中/英 SPEC）
- Workflow B 中間產物：`spec_refined.md`、`timing_plan.md`、`collaboration_log.md`
- `workflow-b-pipeline/templates/` 中英範本
- `prompts/` 可貼上指令（每個 workflow 有 `.zh.md` / `.en.md`）
- `experiments/` 實驗紀錄說明

### 2.2 Cursor 設定

| 類型 | 路徑 | 說明 |
|------|------|------|
| Skill | `.cursor/skills/rtl-workflow-a/` | Workflow A：`@rtl-workflow-a` |
| Skill | `.cursor/skills/rtl-pipeline-workflow-b/` | Workflow B：`@rtl-pipeline-workflow-b` |
| Rules | `.cursor/rules/workflow-a.{zh,en}.mdc` | A 路徑／Pass@1 約束（輔助） |
| Rules | `.cursor/rules/workflow-b.{zh,en}.mdc` | B 路徑／Pass@1 約束（輔助） |
| Reference | `.../reference.{zh,en}.md` | `timing_plan.md` 章節格式 |
| Ignore | `.cursorignore` | 排除 RTLLM／verified／testbench 索引 |

**建議啟動**：只 `@rtl-workflow-a` 或 `@rtl-pipeline-workflow-b`（見 `README.md`）。`prompts/` 為可選短指令。

索引檔：`workflow-a.mdc`、`workflow-b.mdc`、各 `SKILL.md`、`README.md`、`AGENTS.md`。

### 2.3 設計決策（已討論、已寫入文件）

- **流程控制**：Rules + Skills + 目錄約定即可；**不必**為 workflow 本身做 MCP
- **指令語言**：Agent 規則/Skill 中英分檔；**SPEC 內容**可中可英
- **MCP / VCS**：建議主實驗用 **Pass@1**（不給 sim 反饋）；VCS 閉環除錯當**延伸實驗**，避免與 A/B 主比較混淆
- **Benchmark**：傾向 **RTLLM v2.0**（NL `design_description.txt` + Makefile/TB + VCS），優於 verilog-eval 對本題的契合度

### 2.4 試跑紀錄（本機，2026-05-25）

- 題目：**adder_pipe_64bit**（`spec/design.spec.txt`）
- Workflow A / B 皆曾產出 `adder_pipe_64bit.v`；VCS 編譯可過，**功能仿真曾 hang**（`o_en` 未拉高），需修 RTL 或對照 pipeline 時序
- RTLLM 放在同層 `../RTLLM/`（**勿**在生成對話 @ 進 repo）

### 2.5 Git

- Repo：`GENRTL` on GitHub
- 本次 push 重點：Workflow A skill、Pass@1 規則、`.cursorignore`、README／HANDOFF 更新

---

## 3. 尚未完成 ⏳

| 項目 | 狀態 |
|------|------|
| 穩定 VCS pass（adder_pipe_64bit 等） | ⏳ 試跑未過功能測試 |
| `experiments/` 正式 run 紀錄 | ⏳ 建議補每題 A/B 各一筆 |
| 克隆 / 掛載 **RTLLM v2.0** 於 repo 外 `rtllm_env/` | 可選（本機已有 sibling `RTLLM/`） |
| `benchmarks/rtllm_manifest.yaml` | ❌ 未建 |
| `scripts/run_vcs.sh` 批次評測 | ❌ 未建 |
| MCP `run_vcs_simulation`（可選） | ❌ 未建 |

---

## 4. 專案架構（當前）

```
final/                          ← Cursor 開這個資料夾
├── HANDOFF.md                  ← 本檔（交接）
├── spec/                       ← 【輸入】唯讀原始 SPEC
├── workflow-a-direct/rtl/      ← 【Workflow A 輸出】
├── workflow-b-pipeline/        ← 【Workflow B 輸出 + 中間檔】
│   ├── spec_refined.md
│   ├── timing_plan.md
│   ├── collaboration_log.md
│   ├── rtl/
│   └── templates/
├── prompts/                    ← 複製貼到 Agent
├── experiments/
└── .cursor/
    ├── rules/
    └── skills/
        ├── rtl-workflow-a/
        └── rtl-pipeline-workflow-b/
```

**計畫中的上層結構（工作站）**：

```
cursor_experiment/              ← 可選：父目錄
├── rtllm_env/                  ← RTLLM clone（裁判，待建）
└── final/                      ← 本 repo（生成區）
```

---

## 5. 工作站上的第一步（建議順序）

### 5.1 取得程式碼

```bash
git clone git@github.com:jasonpan0930/GENRTL.git final
cd final
```

或在已有目錄：`git pull origin main`

### 5.2 開啟 Cursor

- **Open Folder** → 選 `final/`（內含 `.cursor/`，rules/skills 才會生效）
- 使用 **Agent 模式**（非 Ask）

### 5.3 驗證 Cursor 設定

在 Agent 對話測試：

```
列出 .cursor/rules 與 .cursor/skills 下與 workflow 相關的檔案，並簡述 Workflow A 與 B 的輸出路徑。
```

應能引用 `@rtl-workflow-a`、`@rtl-pipeline-workflow-b` 與對應 `SKILL.*.md`。

### 5.4 接 RTLLM（下一階段實作）

1. 在 `final` 同層 clone RTLLM → `../rtllm_env/`（路徑依工作站調整）
2. 選一題（例如 **adder_pipe_64bit**）：
   - 複製 `design_description.txt` → `spec/design.spec.txt`（或 `design.spec.md`）
   - **人工**從 `testbench.v` 確認 top／port 後寫入 `spec/`（生成 Agent **勿**讀 testbench／`verified_*.v`；見 `.cursorignore`）
3. 跑 Workflow A / B，產出 `.v` 後複製到 RTLLM 該題目錄
4. `make vcs && make sim`（確認 `VCS_HOME`、license）
5. 結果記入 `experiments/YYYY-MM-DD_run01.md`

### 5.5 第一次實驗 prompt（中文）

**Workflow A**：`@rtl-workflow-a`（可選 `SPEC: spec/design.spec.txt`）

**Workflow B 全流程**：`@rtl-pipeline-workflow-b`

---

## 6. 實驗設計備忘（論文用）

### 主比較（Primary）

- 同一 RTLLM 題目、同一 SPEC 來源
- **Pass@1**：每題每 workflow 只生成 **1 次**，不讀 VCS log 迭代
- 指標：RTLLM/VCS pass rate、必要時 syntactic check

### 延伸（Secondary，可選）

- **Repair@k**：僅 Workflow B（或 B+tool）允許讀 VCS log 修改 RTL，最多 k 次
- 中間產物分析：spec_refined 完整度、timing_plan 覆蓋率、協作輪數

---

## 7. 快速對照表

| 想做什麼 | 用什麼 |
|----------|--------|
| 中文跑 Workflow A | `@rtl-workflow-a`（SKILL.zh.md） |
| 英文跑 Workflow A | `@rtl-workflow-a`（SKILL.en.md） |
| 中文跑 Workflow B 全流程 | `@rtl-pipeline-workflow-b`（SKILL.zh.md） |
| 只跑 Agent1/2/3 | `@rtl-pipeline-workflow-b` + 註明階段，或 `prompts/workflow-b-agent{1,2,3}.zh.md` |
| 專案與 Agent 說明 | `AGENTS.zh.md` / `AGENTS.en.md` |
| 完整中文說明 | `README.zh.md` |

---

## 8. 本機 vs 工作站差異注意

- [ ] 重新 `git clone` 或 `pull` 確保 `.cursor/` 有同步
- [ ] Cursor 登入同一帳號（若用 Cloud Agent 則另論）
- [ ] VCS / license 僅工作站有——評測腳本應在工作站跑
- [ ] 路徑不要用 Windows 專用寫死；腳本用 `$PWD` 或環境變數 `RTLLM_ROOT`
- [ ] `workflow-a-direct/rtl/` 若 clone 後不存在，可 `mkdir -p workflow-a-direct/rtl workflow-b-pipeline/rtl`

---

## 9. 待辦清單（接手後優先）

1. [ ] 工作站 `git pull`，Cursor 開啟 `final/`
2. [ ] Clone RTLLM v2.0 到 `rtllm_env/`
3. [ ] 每題：`design_description.txt` → `spec/design.spec.txt`
4. [x] 試跑 **Workflow A / B**（adder_pipe_64bit）— VCS 功能待修
5. [ ] 修 RTL 或 SPEC 後重跑 `make sim` 並寫 `experiments/`
6. [ ] 新增 `benchmarks/` + `scripts/run_vcs.sh`（可請 Cursor 協助）
7. [ ] 撰寫第一筆 `experiments/..._run01.md`
8. [ ] （可選）更新 Skill：RTLLM 部署與 module 命名規則

---

## 10. 對話脈絡（給新 Cursor session）

已完成：**Workflow B skill + Workflow A skill（`rtl-workflow-a`）**、Pass@1 讀取限制、`.cursorignore`、文件改為 **@skill 啟動**。已試跑 adder_pipe_64bit（A/B），VCS 仿真待修。

在新對話可貼：

```
請讀 @HANDOFF.md。用 @rtl-workflow-a 或 @rtl-pipeline-workflow-b，SPEC 在 spec/design.spec.txt。
```
