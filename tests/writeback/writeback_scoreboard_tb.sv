// Exercises order-independent pairing, object snapshots, masks and diagnostics.
module writeback_scoreboard_tb;
  timeunit 1ns;
  timeprecision 1ps;
  import uvm_pkg::*;
  import writeback_out_pkg::*;
  import writeback_env_pkg::*;
  `include "uvm_macros.svh"
  // Questa resolves virtual BFM types registered by the imported agent classes
  // even though this unit test creates only a scoreboard. Supply inert instances.
  writeback_in_if in_bus(
    .clock(1'b0), .reset(1'b0), .enable_writeback(1'b0), .W_Control(2'b0),
    .aluout(16'b0), .memout(16'b0), .pcout(16'b0), .npc(16'b0),
    .sr1(3'b0), .sr2(3'b0), .dr(3'b0));
  writeback_out_if out_bus(
    .clock(1'b0), .sr1(3'b0), .sr2(3'b0), .d1(16'b0), .d2(16'b0), .psr(3'b0));
  writeback_in_monitor_bfm in_bfm(in_bus);
  writeback_out_monitor_bfm out_bfm(out_bus);

  class writeback_scoreboard_test extends uvm_test;
    `uvm_component_utils(writeback_scoreboard_test)
    writeback_scoreboard scoreboard;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      scoreboard = writeback_scoreboard::type_id::create("scoreboard", this);
    endfunction
    task run_phase(uvm_phase phase);
      writeback_expected_transaction e;
      writeback_out_transaction a;
      phase.raise_objection(this);
      for (int i = 1; i <= 3; i++) begin
        e = writeback_expected_transaction::type_id::create("expected");
        a = writeback_out_transaction::type_id::create("actual");
        e.edge_time_ps = i*100;
        a.edge_time_ps = e.edge_time_ps;
        e.sample = '0;
        e.sample.d1 = 16'd9;
        e.sample.d2 = 16'd7;
        e.sample.psr = 3'b001;
        e.check_d1 = (i != 2);
        e.check_d2 = (i != 2);
        e.check_psr = (i != 2);
        a.sample = e.sample;
        if (i == 2 || (i == 3 && $test$plusargs("WB_UNIT_FAULT"))) begin
          a.sample.d1 = 'x;
          if (i == 2) begin
            a.sample.d2 = 'x;
            a.sample.psr = 'x;
          end
        end
        scoreboard.actual_export.write(a); // Actual deliberately arrives first.
        a.sample = 'x; // Stored snapshot must remain unchanged.
        scoreboard.expected_export.write(e);
        if (i == 3 && $test$plusargs("WB_DUPLICATE"))
          scoreboard.expected_export.write(e);
      end
      if (scoreboard.pairs != 3 || scoreboard.field_checks != 6 ||
          scoreboard.unchecked_pairs != 1)
        `uvm_error("WB_SELFTEST", "Pairing, mask or field count failure")
      if ($test$plusargs("WB_PENDING")) begin
        e = writeback_expected_transaction::type_id::create("unpaired");
        e.edge_time_ps = 400;
        scoreboard.expected_export.write(e);
      end
      #1ns;
      phase.drop_objection(this);
    endtask
  endclass
  initial run_test("writeback_scoreboard_test");
endmodule
