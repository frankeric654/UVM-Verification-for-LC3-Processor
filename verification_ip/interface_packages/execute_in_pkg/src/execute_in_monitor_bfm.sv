// Passive signal-to-transfer adapter.
// The UVM monitor will call monitor().
interface execute_in_monitor_bfm (execute_in_if bus);
  timeunit 1ns;
  timeprecision 1ps;

//這裡匯入的是 Struct Type，不是 execute_in_transaction Class
  import execute_in_types_pkg::*;

  // Observe one rising edge and capture all Execute input signals.
  /*執行流程：
    1. UVM Monitor 呼叫 monitor()。
    2. BFM 等待 Clock。
    3. BFM 將所有 Input Signals 存入 sample。
    4. Task 結束，sample 的值複製回呼叫者的 data。*/
  task automatic monitor(output execute_in_transfer_t sample);
    @(bus.monitor_cb);

    sample.reset          = bus.monitor_cb.reset;
    sample.enable_execute = bus.monitor_cb.enable_execute;
    sample.E_Control      = bus.monitor_cb.E_Control;

    sample.bypass_alu_1   = bus.monitor_cb.bypass_alu_1;
    sample.bypass_alu_2   = bus.monitor_cb.bypass_alu_2;
    sample.bypass_mem_1   = bus.monitor_cb.bypass_mem_1;
    sample.bypass_mem_2   = bus.monitor_cb.bypass_mem_2;

    sample.IR             = bus.monitor_cb.IR;
    sample.npc            = bus.monitor_cb.npc;

    sample.Mem_Control_in = bus.monitor_cb.Mem_Control_in;
    sample.W_Control_in   = bus.monitor_cb.W_Control_in;

    sample.Mem_Bypass_Val = bus.monitor_cb.Mem_Bypass_Val;
    sample.VSR1           = bus.monitor_cb.VSR1;
    sample.VSR2           = bus.monitor_cb.VSR2;
  endtask

endinterface