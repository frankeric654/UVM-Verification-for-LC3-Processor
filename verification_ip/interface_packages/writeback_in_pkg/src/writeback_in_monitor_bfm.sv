// Passive signal-to-transfer adapter. The UVM monitor will call monitor().
interface writeback_in_monitor_bfm (writeback_in_if bus);
  timeunit 1ns;
  timeprecision 1ps;

  import writeback_in_types_pkg::*;

  // One call observes one rising edge. Include reset and disabled cycles so
  // the predictor can track reset and verify that writes remain disabled.
  task automatic monitor(output writeback_in_transfer_t sample,
                         output time edge_time_ps);
    @(bus.monitor_cb);
    edge_time_ps = time'($realtime / 1ps);

    sample.reset            = bus.monitor_cb.reset;
    sample.enable_writeback = bus.monitor_cb.enable_writeback;
    sample.W_Control        = bus.monitor_cb.W_Control;
    sample.aluout           = bus.monitor_cb.aluout;
    sample.memout           = bus.monitor_cb.memout;
    sample.pcout            = bus.monitor_cb.pcout;
    sample.npc              = bus.monitor_cb.npc;
    sample.sr1              = bus.monitor_cb.sr1;
    sample.sr2              = bus.monitor_cb.sr2;
    sample.dr               = bus.monitor_cb.dr;
  endtask
endinterface
