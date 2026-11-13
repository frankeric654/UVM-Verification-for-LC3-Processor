# WB 逐段教學筆記

先看 configuration，再看 environment，最後看 test。這份是程式對照與後續教學順序，
不需要一次理解全部內容。架構目前使用一般 UVM，尚未改成 UVMF。

## 1. Configuration：把設定包成物件

位置：`verification_ip/interface_packages/writeback_in_pkg/src/writeback_in_configuration.svh`，
output package 有對應版本。

```systemverilog
class writeback_in_configuration extends uvm_object;
  `uvm_object_utils(writeback_in_configuration)
  virtual writeback_in_monitor_bfm monitor_bfm;
  // constructor 只呼叫 super.new(name)
endclass
```

Configuration 是資料物件，因此繼承 uvm_object，不是 uvm_component；沒有 parent
階層參數，也不會自行執行 build_phase／run_phase。monitor_bfm 是 handle，預設 null。

Smoke bench 在 run_test 前建立 configuration，填入已實例化的 interface handle：

```systemverilog
in_cfg = writeback_in_configuration::type_id::create("in_cfg");
in_cfg.monitor_bfm = in_bfm;
uvm_config_db#(writeback_in_configuration)::set(
  null, "uvm_test_top.env.in_agent", "configuration", in_cfg);
```

create 建立的是 configuration 物件；第二行不建立 BFM，只保存原有 handle。
config_db 傳遞的也是 configuration handle，不會複製物件。

Agent 在 build_phase 取得它，並在建立 monitor 前設定 child 路徑：

```systemverilog
uvm_config_db#(writeback_in_configuration)::set(
  this, "monitor", "configuration", configuration);
monitor = writeback_in_monitor::type_id::create("monitor", this);
```

Monitor 的 build_phase 再取得同一個 configuration，執行
`bfm = configuration.monitor_bfm`。BFM 的實際 instance 始終只有原來那一個。
Agent 和 monitor 都會檢查 null；設定完後不要在取樣中途更換其 BFM handle。

## 2. Environment：建立元件，再接通資料

位置：`verification_ip/environment_packages/writeback_env_pkg/src/writeback_environment.svh`。

Environment 繼承 uvm_env，管理 in_agent、out_agent、predictor、scoreboard、coverage。
new 只建立 environment 本身；build_phase 用 factory 建立五個 child 元件。
UVM 會接著呼叫 child 的 build_phase，不是 environment 手動呼叫它們。

connect_phase 建立四條資料連線：

```systemverilog
in_agent.analysis_port.connect(predictor.analysis_export);
in_agent.analysis_port.connect(coverage.analysis_export);
predictor.analysis_port.connect(scoreboard.expected_export);
out_agent.analysis_port.connect(scoreboard.actual_export);
```

同一筆 input 會傳給 predictor 與 coverage。前者產生答案，後者記錄刺激分布；
output agent 則把 DUT 實際結果交給 scoreboard。connect 只建立通道，不會立刻產生
transaction，也不會自動複製物件。Scoreboard 另外 clone 接收資料以保存副本。

Environment 不產生 clock、不驅動 WB 輸入，也不控制測試長度。這些由 bench／test 負責。
教授 model 使用 static state，因此一次模擬只建立一個 WB environment／predictor。

## 3. Smoke test：先檢查驗證程式自己能否運作

位置：`tests/writeback/writeback_smoke_tb.sv`。

同一個檔案裡有兩部分：module 提供 HDL 訊號和刺激，內嵌的 UVM test class 管理
驗證環境和測試生命週期。這是 WB infrastructure 自測，不是最後 LC3 指令測試。

Module 每 5ns 翻轉 clock，產生 10ns 週期。獨立的 behavioral fixture 保存自己
的 regs／PSR，沒有與教授 model 共用 storage。Testbench 建立 interfaces、BFMs，
用 configuration 把 handle 傳入 UVM，最後呼叫 run_test。

Test 的 build_phase 建立 environment；run_phase raise objection，等待 module
設 done，最後等待 1ns 後 drop objection。done 在最後一個 negedge 設定，此時前一個
posedge 的取樣已完成；多等 1ns 仍在下一個 posedge 前，避免留下新一筆未結束資料。
另有 10us timeout 防止無限等待。

`drive()` task 等 negedge 再改輸入，讓資料在下一個 posedge 前穩定。它把沒有使用的
資料來源設 X，確認 predictor 不會因無關 X 而跳過有效寫入。測試輪流寫八個 register、
使用三種來源，穿插 disabled 讀取、同址讀寫、覆寫、負零正邊界、未知寫入與 reset。
另外刻意在 posedge 的 NBA 更新 sr1，確認 monitor 使用的是寫入前取樣地址。

加 `+WB_FAULT_D1` 或 `+WB_FAULT_PSR` 會破壞 fixture 的輸出；scoreboard 必須報
WB_MISMATCH。這能證明測試不是永遠顯示成功。`+WB_MISSING_CONFIG` 和
`+WB_NULL_BFM` 分別檢查遺漏設定與空 BFM handle，應在 time zero 報 fatal。

## 4. Scoreboard 單元測試與 regression

`tests/writeback/writeback_scoreboard_tb.sv` 直接建立預期／實際 transaction，
不使用 DUT：刻意讓 actual 先到，再修改送出的原物件，驗證配對和 clone。
另測遮罩、實際 X、重複 edge 與結束未配對。Questa 要求 imported monitor 的
virtual BFM 型別能找到 instance，因此此 top 也建立不運作的 BFM instance。

`scripts/writeback/regress.sh` 每個 case 啟動新的 simulator，避免教授 static
model state 跨 test 殘留。除了 process exit status，script 也檢查 UVM report 的
error／fatal 數量、診斷 ID 與 coverage 產物。負向測試刻意有 error／fatal 才算通過；
不能直接把「有 UVM_ERROR」全部判定為 regression 失敗。

正常 smoke 的 coverage 與錯誤注入分開保存。WB covergroup coverage 不等於整份
作業要求的 instruction coverage，也不等於專案完成百分比。
