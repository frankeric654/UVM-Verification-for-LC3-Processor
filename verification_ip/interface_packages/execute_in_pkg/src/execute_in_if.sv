//定義 Execute Input Monitor 要觀察的訊號
interface execute_in_if (
  input wire        clock,
  input wire        reset,
  input wire        enable_execute,
  input wire [5:0]  E_Control,
  input wire        bypass_alu_1,
  input wire        bypass_alu_2,
  input wire        bypass_mem_1,
  input wire        bypass_mem_2,
  input wire [15:0] IR,
  input wire [15:0] npc,
  input wire        Mem_Control_in,
  input wire [1:0]  W_Control_in,
  input wire [15:0] Mem_Bypass_Val,
  input wire [15:0] VSR1,
  input wire [15:0] VSR2
);

  timeunit 1ns;
  timeprecision 1ps;
//clocking block
  clocking monitor_cb @(posedge clock);
    default input #1step;

    input reset;
    input enable_execute;
    input E_Control;
    input bypass_alu_1;
    input bypass_alu_2;
    input bypass_mem_1;
    input bypass_mem_2;
    input IR;
    input npc;
    input Mem_Control_in;
    input W_Control_in;
    input Mem_Bypass_Val;
    input VSR1;
    input VSR2;

  endclocking

endinterface
