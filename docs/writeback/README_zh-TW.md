# Writeback：逐步實作筆記

[English](README.md)

負責人：Cheng-Wei（clin39）；分支：`stage/writeback`。

## 目前進度（2026-11-11）

已有 input/output passive agent、interface、clocking block、BFM、四態資料型別、
transaction、monitor，以及 predictor adapter、scoreboard、WB functional coverage
和 `writeback_environment`。程式使用 UVM 1.2；與組員 UVMF configuration／wrapper
及完整 LC3 bench 的接合仍待完成。兩個 WB agent 都不建立 driver／sequencer。

```text
in_agent → predictor → scoreboard 的預期值入口
         → coverage
out_agent            → scoreboard 的實際值入口
```

## Configuration 的資料路徑（維持一般 UVM）

已加入 `writeback_in_configuration`、`writeback_out_configuration`，都繼承
`uvm_object`，各自保存 virtual `monitor_bfm` handle。建立 configuration 不會建立
BFM；testbench 將既有 BFM handle 放入物件，透過 config_db 的 `configuration`
設定名稱交給對應 agent。Agent 取得並檢查後，把同一個物件傳給 child monitor；
monitor 再用 `configuration.monitor_bfm` 進行取樣。

這取代先前直接把 virtual BFM 放在 monitor 路徑下的做法。連線 helper 和 smoke bench
已同步更新；沒有導入 UVMF，也沒有改成學長的繼承架構。兩個 agent 固定 passive，
目前不提供 active 模式設定。缺少／null configuration 回報 `NO_CONFIG`；BFM 為 null
回報 `NO_BFM`，都在初始化期間停止，避免進入取樣後才發現空 handle。

新增測試可用 `WB_TEST_SUITE=configuration bash scripts/writeback/regress.sh` 執行，
涵蓋正常 smoke、缺少設定和 null BFM；預設完整 regression 為九項。
後兩項是負向測試，預期各有一個 fatal，script 會檢查 ID 和發生時間。

教學順序與 environment／test 的程式對照見
[逐段教學筆記](WALKTHROUGH_zh-TW.md)。對話中先講 configuration，再講 environment，
最後講 test；這份筆記供回頭查閱，不表示需要一次全部讀完。

## 教授 model 與取樣約定

Predictor 呼叫教授原始的 `lc3_prediction_pkg::writeback_model`，未修改或複製教授
原始檔到公開 repo。其 static register array 為共用狀態，每次模擬只能有一個 WB
predictor／model 呼叫者；每個測試應重新啟動模擬，不能靠建立新 environment 清除模型。

教授 model 先讀 register，再執行本次寫入。因此 input、output 的 sr1/sr2/d1/d2
都在上升緣前以 `input #1step` 取樣；output PSR 以 `input #0` 在 Observed region
取得一般 RTL 的 NBA 與組合邏輯更新後結果。一筆 output 刻意包含「寫入前讀值」與
「寫入後 PSR」，取代先前所有 output 都在更新後取樣的做法。目前只在 clock edge
檢查讀值，沒有逐次檢查兩個 edge 之間所有非同步讀取變化。

BFM 回傳以 ps 為單位的絕對 edge 時間，transaction 用 `edge_time_ps` 保存。
Scoreboard 按此標記配對，不依賴 callback 抵達順序。假設同一時脈域且每 ps 最多一個
上升緣。接收端 clone transaction，使用 `!==` 比較以抓到非預期 X/Z，並檢查重複、
結束時未配對，以及沒有有效比較的情況。

## X、disabled 與 reset

Reset 時序已對齊組員 `imem_coverage` 的 HDL top：active-high，保持五個 clock
上升緣，然後以 `reset <= 1'b0` 在 NBA 解除。自測的啟動與中途 reset 都使用
`apply_reset()`；`drive()` 不再自行解除 reset。整合時 WB 是 passive，直接觀察
團隊 top 的同一條 reset，不另外產生 reset，也不要求一定維持五個週期才可工作。
來源：[團隊 HDL top](https://github.com/frankeric654/UVM-Verification-for-LC3-Processor/blob/imem_coverage/project_benches/imem_fetch_sandbox/tb/testbench/hdl_top.sv)。

這裡統一的是「reset 的產生時序」，不是把 Fetch 的 PC reset 規格套到 WB。
學長 WB 的 `wait_for_reset()` 主要等 reset 解除；其 predictor 呼叫的教授
`writeback_model()` 也沒有 reset 參數，因此不能由此推論 WB PSR 或 register 的
reset 值。現有 predictor 保留狀態有效標記失效、之後重新建立預期值的處理。


教授 model 的 bit 參數不保留 X/Z，因此 adapter 用 `reg_known` 記錄每個 register
是否有可信的完整預期值。讀值有效標記在本次寫入前取得。尚未初始化的 register
暫不比較；有效寫入後，後續 edge 才可比較。已知預期值遇到實際 X/Z 會報錯。

有效寫入需要 enable、dr、選擇與被選取的資料皆已知；未使用資料來源的 X 不影響寫入。
Disabled 仍預測讀取，PSR 使用暫存的最後有效預期值。未知或未定義的有效寫入不會直接
以二態值寫進教授模型，而是使受影響的狀態標記失效並發出 `WB_UNDEFINED_WRITE`。
W_Control=11 沒有已確認定義，不能假設選 npc。預期值不讀取 DUT register 來計算。

提供的 WB 文字規格／model 尚不足以確定 reset 值。Reset=1 或 X 時，adapter 不呼叫
model，清除已知標記並送出不比較的 sample；之後由已知寫入重新建立可信狀態。
因此目前「不驗證 reset 值與跨 reset 的 register 保留行為」，不能宣稱 reset 驗證完成。
Scoreboard 的 `unchecked_pairs` 會顯示整筆未檢查的數量。

## 編譯與基礎測試

先載入 simulator 和 license 環境。在學校機器可使用：

```bash
source /etc/profile.d/modules.sh
module use /mnt/apps/modules/ece
module load mentor/questa/2024.2
bash scripts/writeback/compile.sh
bash scripts/writeback/regress.sh
```

在 repo 根目錄執行。可設定 `QUESTA_HOME`、`LC3_PREDICTION_DIR`，後者預設為
`../lc3_prediction_pkg`。`WB_BUILD_DIR` 可指定輸出目錄，預設建立於 `/tmp`。
編譯順序為教授 package、types、interfaces、BFMs、input/output packages、environment
package，最後是測試檔；使用相同版本 UVM 1.2 library 與 header。

Smoke fixture 是另寫的簡單行為模型，不是老師 LC3 RTL，也不是作業最終模擬證據。
測試包含所有 register、三種資料來源、disabled 讀寫、同 register 讀寫、覆寫、正負零
邊界、未使用來源的 X、未知寫入後重新初始化、NBA 時改讀取地址，以及 reset 後重建狀態。
負向測試刻意破壞 d1／PSR；其他測試涵蓋 actual 先抵達、clone 隔離、未知值遮罩、
已知預期遇到實際 X、重複與未配對交易。Regression 檢查 UVM error 數量及 ID，
不只看 process exit code。Log／UCDB 留在輸出目錄。這是 WB functional coverage，
團隊的 instruction coverage／test plan 仍需完成。結果見 [VALIDATION.md](VALIDATION.md)。

## 組員接入完整 LC3 的方式

1. 依上述順序編譯，加入各 package 的 src include path。
2. 在 LC3 environment 的 build_phase 建立一個 `writeback_environment`，例如命名
   `writeback_env`，並 import `writeback_env_pkg`。
3. 在 HDL top 內 include `integration/writeback/writeback_connections.svh`；DUT instance
   不叫 dut 時設定 `WB_DUT_PATH`。連線使用 WB module 的實際 ports，因此控制訊號
   會接到 LC3 的 W_Control_out，而非 Decode 的 W_Control。
4. 在 run_test() 前呼叫 `configure_writeback_bfms("uvm_test_top.env.writeback_env")`，
   字串改成實際 environment 路徑。HDL/HVL 分開時，可由啟動 run_test 的 initial block
   透過 HDL top 階層呼叫這個 function。
5. 由完整 LC3 的 imem/dmem responder 提供刺激，用指令初始化 register；最後取樣完成
   後才 drop objection。WB monitor 不自行 raise objection。

連線片段已在暫存 probe top 與老師的加密 LC3 RTL 一起編譯通過，零 error/warning；
尚未在團隊完整 bench 模擬。實際 instance 路徑、
responder 分工與 UVMF wrapper 尚未在本機確定；基礎 regression 通過不代表 P3 全部完成。
