# Writeback：逐步實作筆記

[English](README.md)

負責人：Cheng-Wei（clin39）；分支：`stage/writeback`。

## 作業範圍

P3 是 LC3 的 UVM/UVMF 驗證環境。老師已提供 Writeback RTL；我們負責
`writeback_in_pkg`、`writeback_out_pkg`、`writeback_env_pkg`。
兩個 agent 都是 passive：只觀察 LC3 內部訊號，不能驅動訊號。
predictor 算預期結果，scoreboard 比較預期與實際結果。
依 assignment slides 7–9，最終在完整 LC3 bench 模擬。
團隊分五個人的工作，但作業要求六個 sub-environment，Decode 也需要整合。

## 本機位置

`ECE748/clin39_p3/` 放原始 PDF 和 RTL ZIP；`repo/` 是 GitHub checkout。
公開 repo 目前只新增自己的驗證原始碼與筆記。

## 學習與實作順序

1. **本次：訊號與資料型別。** 看下方對照表及兩個 `*_types_pkg.sv`。
2. 建 input/output interface 與 monitor BFM，確認取樣點。
3. 建 transaction、monitor、configuration、passive agent 與 coverage。
4. 建有狀態的 predictor，追蹤八個暫存器和 PSR。
5. 建 scoreboard，處理對齊、未知值及結束時未比較資料。
6. 建 environment，連接 analysis ports，接入組員的 LC3 bench。
7. 在 LC3 level 執行測試，記錄 bug、coverage、transcript，再提交。

目前已建立 input/output 型別及 `writeback_in_if.sv`，還不是可執行的 UVM environment。
input interface 的所有 port 都是 `input wire`，由 LC3 bench 接入訊號。
方向以此 interface 為準，因此 MemAccess 的 output `memout` 在這裡是 input。
interface 已加入 `monitor_cb`，以 `input #1step` 定義上升緣前的取樣值；
本地 timeunit 為 1ns、timeprecision 為 1ps。已實作 `writeback_in_monitor_bfm.sv` 的 `monitor` task，等待 clocking event
後將所有欄位複製進 output struct；每次呼叫觀察一個上升緣，包含 reset 和
writeback disabled 週期。BFM 不驅動 DUT；UVM monitor class 尚未實作。

## WB 訊號對照

以下以提供的 `TopLevelLC3.v` 中 `Writeback WB` 的連接為準。
假設頂層 DUT instance 叫 `dut`，右欄是 `dut` 內部的訊號名。

| WB port / 型別欄位 | bits | LC3 內訊號 | 用途 |
| --- | --- | --- | --- |
| clock | 1 | clock | 寫入時脈；不是 transaction payload |
| reset | 1 | reset | reset；必須讓 predictor 看得到 |
| enable_writeback | 1 | enable_writeback | 是否允許寫入 |
| W_Control | 2 | W_Control_out | 選擇寫回資料 |
| aluout | 16 | aluout | ALU 結果 |
| memout | 16 | memout | load 讀回資料 |
| pcout | 16 | pcout | LEA 位址結果 |
| npc | 16 | npc_out_dec | 保留 RTL port；合法選擇 0/1/2 不使用它 |
| sr1, sr2 | 各 3 | sr1, sr2 | 讀取 R0–R7 的位址 |
| dr | 3 | dr | 寫入 R0–R7 的位址 |
| d1 | 16 | VSR1 | 非同步讀取 RegFile[sr1] |
| d2 | 16 | VSR2 | 非同步讀取 RegFile[sr2] |
| psr | 3 | psr | 負、零、正旗標 |

`d1/d2` 是 RTL port 名稱，`VSR1/VSR2` 是 top-level wire 名稱。
input/output 的 struct 是 monitor 要傳送的資料格式，不會自己觀察 DUT。
使用 `logic` 保留 X/Z，避免未知值被轉成 0 後掩蓋問題。

## 預期功能

Design spec WRITEBACK 小節及 P2 提供的 writeback_model 支持：

| W_Control | 寫入資料 |
| --- | --- |
| 2'b00 | aluout |
| 2'b01 | memout |
| 2'b10 | pcout |

`2'b11` 先列為待釐清，不自行假設為 npc。
enable_writeback 有效時寫入 RegFile[dr]，並依寫入值更新 PSR：
負數 100、零 010、正數 001。沒有寫入時應保留先前狀態。
R0 是普通可寫暫存器，不能當成固定的 zero register。
VSR1/VSR2 為非同步讀取，即使 writeback disable 仍要檢查讀取。

## 時序與未知值：實作前要確認

- Spec 說 register file 初始可能是 X，不能在 reference model 裡任意清成零。
  為每個暫存器追蹤是否已初始化；測試先透過指令初始化暫存器。
- WB reset 對 PSR 的精確值、register file 保留行為，需在實作 predictor 前核對。
- 在上升緣前擷取本次寫入的 enable、dr、選擇與資料。
  Execute 也在上升緣更新輸出，不能用更新後的 dr 搭配上一筆寫入。
- Output monitor 等待 NBA 與組合邏輯穩定後取樣，使用此時的 sr1/sr2 查模型。
  input/output 必須有共同的 cycle 對齊方式；不能只靠 callback 先後順序。
- P2 的 writeback_model 有 static regfile、bit ports，且先讀再寫；不宜原封不動
  用來預測上升緣後的非同步讀值。會另做每個 predictor instance 自有的狀態。

## 規劃的驗證案例

三種資料來源；八個 dr/sr1/sr2；負/零/正與邊界值；disable 保持；
同一個 register 讀寫；連續覆寫；不同 sr 的非同步讀取；啟動未知值；reset。
刺激由完整 LC3 的 instruction/data memory responder 產生，WB agent 不驅動 DUT。

## 整合需要組員提供的資料

共同 UVMF 版本與 generator 慣例、LC3 bench instance 名稱、共同 sampling/cycle
約定，以及頂層 integration 和 imem/dmem 的負責人。這些不影響先理解訊號。

## 本次驗證範圍

2026-11-03 使用 Questa 2024.2 依序編譯 input types、input interface、input
monitor BFM，結果為零 error、零 warning。編譯庫放在 `/tmp`，未加入 repo。
先前受限環境中的編譯失敗已排除；本次以安裝的 compiler 在 sandbox 外成功執行。
目前確認語法與型別能編譯，尚未執行模擬、取樣時序驗證或 coverage。

重現方式：在 repo 根目錄執行 `vlib <暫存編譯庫>`，再以
`vlog -work <暫存編譯庫> -sv` 依序編譯：

1. `verification_ip/interface_packages/writeback_in_pkg/src/writeback_in_types_pkg.sv`
2. `verification_ip/interface_packages/writeback_in_pkg/src/writeback_in_if.sv`
3. `verification_ip/interface_packages/writeback_in_pkg/src/writeback_in_monitor_bfm.sv`

## Input transaction

已新增 `writeback_in_transaction.svh`，繼承 `uvm_sequence_item`，內含
`writeback_in_transfer_t sample`。Factory/field macros 註冊類別與 packed
payload；constructor 將物件名稱傳給父類別。每筆取樣都要建立新的 transaction，
因為複製 class handle 不會建立獨立物件。

`writeback_in_pkg.sv` 匯入 UVM 與 types 後 include 此 class；編譯 package，
不要另外編譯 `.svh`。先編譯 types package，再編譯此 UVM package，並將 `src`
加入 include path。2026-11-03 使用 Questa 2024.2、UVM 1.2 編譯通過，零 error/warning。
使用 `-L <questa-install>/uvm-1.2`、
`+incdir+<questa-install>/verilog_src/uvm-1.2/src`，及
`+incdir+verification_ip/interface_packages/writeback_in_pkg/src`。
本機預設 mtiUvm 是 UVM 1.1d，不能搭配 1.2 header；library 與 header 必須一致。
本次僅確認編譯，尚未驗證 transaction 執行行為或 LC3 simulation。
