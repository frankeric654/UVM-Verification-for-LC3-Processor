// Passive view of WB outputs and their corresponding read addresses.
interface writeback_out_if (
  input wire        clock,
  input wire [2:0]  sr1,
  input wire [2:0]  sr2,
  input wire [15:0] d1,
  input wire [15:0] d2,
  input wire [2:0]  psr
);
  timeunit 1ns;
  timeprecision 1ps;

  // Match the supplied model: reads precede the write; PSR follows it.
  clocking monitor_cb @(posedge clock);
    default input #1step;
    input sr1;
    input sr2;
    input d1;
    input d2;
    input #0 psr;
  endclocking
endinterface
