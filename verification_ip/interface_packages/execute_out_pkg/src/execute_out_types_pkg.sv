package execute_out_types_pkg;

  typedef struct packed {
    logic [15:0] aluout;
    logic [15:0] pcout;

    logic [1:0]  W_Control_out;
    logic        Mem_Control_out;

    logic [2:0]  NZP;
    logic [15:0] IR_Exec;

    logic [2:0]  sr1;
    logic [2:0]  sr2;
    logic [2:0]  dr;

    logic [15:0] M_Data;

  } execute_out_transfer_t;

endpackage
