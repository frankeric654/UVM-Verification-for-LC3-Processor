
package execute_in_types_pkg;
  typedef struct packed {
    logic        reset;
    logic        enable_execute;
    logic [5:0]  E_Control;
    logic        bypass_alu_1;
    logic        bypass_alu_2;
    logic        bypass_mem_1;
    logic        bypass_mem_2;
    logic [15:0] IR;
    logic [15:0] npc;
    logic        Mem_Control_in;
    logic [1:0]  W_Control_in;
    logic [15:0] Mem_Bypass_Val;
    logic [15:0] VSR1;
    logic [15:0] VSR2;
  } execute_in_transfer_t;
endpackage
