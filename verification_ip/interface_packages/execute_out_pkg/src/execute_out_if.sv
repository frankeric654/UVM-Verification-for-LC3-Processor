
interface execute_out_if (
  input wire clock,
  input wire [15:0] aluout,
  input wire [15:0] pcout,
  input wire [1:0] W_Control_out,
  input wire Mem_Control_out,
  input wire [2:0] NZP,
  input wire [15:0] IR_Exec,
  input wire [2:0] sr1,
  input wire [2:0] sr2,
  input wire [2:0] dr,
  input wire [15:0] M_Data
);

  timeunit 1ns;
  timeprecision 1ps;

  // Sample Execute output signals on each rising clock edge.
  clocking monitor_cb @(posedge clock);
    default input #1step;

    input aluout;
    input pcout;
    input W_Control_out;
    input Mem_Control_out;
    input NZP;
    input IR_Exec;
    input sr1;
    input sr2;
    input dr;
    input M_Data;

  endclocking

endinterface
