
// Passive signal-to-transfer adapter.
// The UVM monitor will call monitor().
interface execute_out_monitor_bfm (execute_out_if bus);

  timeunit 1ns;
  timeprecision 1ps;

  import execute_out_types_pkg::*;

  // Observe one rising edge and capture Execute output signals.
  task automatic monitor(output execute_out_transfer_t sample);

    @(bus.monitor_cb);

    sample.aluout          = bus.monitor_cb.aluout;
    sample.pcout           = bus.monitor_cb.pcout;

    sample.W_Control_out   = bus.monitor_cb.W_Control_out;
    sample.Mem_Control_out = bus.monitor_cb.Mem_Control_out;

    sample.NZP             = bus.monitor_cb.NZP;
    sample.IR_Exec         = bus.monitor_cb.IR_Exec;

    sample.sr1             = bus.monitor_cb.sr1;
    sample.sr2             = bus.monitor_cb.sr2;
    sample.dr              = bus.monitor_cb.dr;

    sample.M_Data          = bus.monitor_cb.M_Data;

  endtask

endinterface
