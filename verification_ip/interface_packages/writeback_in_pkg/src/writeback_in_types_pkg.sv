// Step 1: shared HDL/HVL payload; passive monitor implementation follows.
package writeback_in_types_pkg;
  typedef struct packed {
    logic        reset;
    logic        enable_writeback;
    logic [1:0]  W_Control;
    logic [15:0] aluout;
    logic [15:0] memout;
    logic [15:0] pcout;
    logic [15:0] npc;
    logic [2:0]  sr1;
    logic [2:0]  sr2;
    logic [2:0]  dr;
  } writeback_in_transfer_t;
endpackage
