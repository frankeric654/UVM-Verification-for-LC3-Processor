# LC3 整合 top 使用說明

[English](README.md)

這個分支以團隊 main `4ff9e12` 為基礎，新增完整 LC3 的 HDL/HVL top 與共同
environment。六個 stage 已能一起編譯與執行。**目前整體 smoke test 有 mismatch，
不是整顆 CPU 驗證通過，也不是已完成所有作業要求。**

## 你要看的檔案

| 檔案 | 工作 |
| --- | --- |
| `project_benches/lc3/tb/testbench/hdl_top.sv` | 建 clock/reset、LC3 instance、六個 stage 的 interface/BFM，以及記憶體連線 |
| `project_benches/lc3/tb/testbench/hvl_top.sv` | 先呼叫設定函式綁定 BFM，再 `run_test()` |
| `verification_ip/environment_packages/lc3_env_pkg/src/lc3_environment.svh` | 建立六個 stage environment 與現有 IMem responder agent |
| `project_benches/lc3/tb/tests/lc3_test_pkg/src/lc3_smoke_test.svh` | 啟動指令 sequence、等待指定 clocks、檢查各 stage 有收到資料 |
| `project_benches/lc3/tb/testbench/lc3_dmem_model.sv` | 整合用資料記憶體模型，支援讀寫與 completion |
| `project_benches/lc3/sim/run.py` | 編譯、載入兩個 top、模擬，並檢查錯誤與測試完成訊息 |

TB 是這整套平台；HDL top 和 HVL top 是其中兩個 module，由模擬器一起載入。
UVM test 建立 `uvm_test_top.env`，底下是 `fetch_env`、`decode_env`、`execute_env`、
`mem_access_env`、`writeback_env`、`control_env` 和 `imem`。

## 如何接上大家的 stage

所有 stage 都是 passive，不能從驗證端驅動 CPU 內部訊號。
`hdl_top.configure_bfms()` 配合各組員現有的 API：Fetch/IMem 使用 UVMF registry；
Decode/MemAccess 使用 `config`；Execute 直接傳 `monitor_bfm`；WB 使用原本的
`writeback_connections.svh`；Control 使用 `configuration`。
HVL 在 `run_test()` 前同步呼叫設定函式，避免兩個 initial block 互相搶先執行。

Questa 仍要求部分未使用的 driver class 有對應 BFM instance；這些相容用 BFM
接在獨立的私有 bus，沒有接到 DUT，也不會成為 active stage agent。

為了讓既有 Decode 能整合，做了三個小修正：input agent 依 is_active 決定是否
建立 driver/sequencer；output package 移除不存在的 driver/sequence include；
output configuration 移除不存在的 driver BFM，並限制 passive。未改 predictors、
scoreboards、老師的 model 或 RTL 來讓錯誤消失。

## dmem 的界線

main 沒有 dmem agent，因此先提供 65,536 個 16-bit word、初始為零的模型。
它保留讀出值供間接定址使用，支援 store，並以 completion pulse 回應。
reset 清除握手輸出但不清記憶體陣列。它是整合用模型，**不是作業要求的正式
UVM dmem agent**，所有協定情境也尚未獨立驗證；之後可換成組員正式版本，
但兩者不能同時驅動 DUT。

## 執行

在此分支 repo 根目錄：

```bash
module load questa/2024.2
export LC3_RTL_DIR=/你的路徑/LC3_veloce_encrypted
export UVMF_HOME=/你的路徑/UVMF_2023.3
export QUESTA_HOME=/你的路徑/questasim
python project_benches/lc3/sim/run.py --seed 1 --cycles 300
```

也可透過 `--rtl-dir`、`--uvmf-home`、`--questa-home` 指定路徑。
`--compile-only` 只編譯；`--out /tmp/lc3-run` 指定 log/編譯庫位置。
老師的 RTL 與 UVMF 使用本機合法副本，不放入本次公開 commit。
UVM 使用配套的 1.2 library/header。預設輸出在已忽略的 `sim/build`。

實測結果與尚待處理問題在 [VALIDATION.md](VALIDATION.md)。若有 UVM error/fatal、
模擬器錯誤或測試沒有完成，runner 會回傳失敗，不會把「能跑」當成「全部通過」。
