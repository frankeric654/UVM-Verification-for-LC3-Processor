// Passive observation only: every port is an input.
interface control_in_if (
    input logic clock, reset,
    input logic complete_data,
    input logic complete_instr,
    input logic [15:0] IR,
    input logic [15:0] IR_Exec,
    input logic [15:0] Instr_dout,
    input logic [2:0] NZP,
    input logic [2:0] psr
);
endinterface
