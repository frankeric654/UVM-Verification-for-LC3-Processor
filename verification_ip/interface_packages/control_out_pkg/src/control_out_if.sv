// Passive observation only: every port is an input.
interface control_out_if (
    input logic clock, reset,
    input logic enable_updatePC,
    input logic enable_fetch,
    input logic enable_decode,
    input logic enable_execute,
    input logic enable_writeback,
    input logic bypass_alu_1,
    input logic bypass_alu_2,
    input logic bypass_mem_1,
    input logic bypass_mem_2,
    input logic [1:0] mem_state,
    input logic br_taken
);
endinterface
