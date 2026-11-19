// Passive adapter: pre-edge reads and post-update PSR for the same clock edge.
interface writeback_out_monitor_bfm (writeback_out_if bus);
  timeunit 1ns;
  timeprecision 1ps;

  import writeback_out_types_pkg::*;

  task automatic monitor(output writeback_out_transfer_t sample,
                         output time edge_time_ps);
    @(bus.monitor_cb);
    edge_time_ps = time'($realtime / 1ps);

    sample.sr1 = bus.monitor_cb.sr1;
    sample.sr2 = bus.monitor_cb.sr2;
    sample.d1  = bus.monitor_cb.d1;
    sample.d2  = bus.monitor_cb.d2;
    sample.psr = bus.monitor_cb.psr;
  endtask
endinterface
