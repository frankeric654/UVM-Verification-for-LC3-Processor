// models the output interface between the DUT and the testbench
interface decode_out_if (
    // signals
    input logic clock,
    input logic reset
    );

    // outputs
    logic [1:0]     W_control;
    logic           Mem_control; // 1 bit
    logic [5:0]     E_control;
    logic [15:0]    IR;
    logic [15:0]    npc_out;
   

    modport DUT (
        input clock, reset,
        output IR, E_control, npc_out, Mem_control, W_control
    );

    modport DRIVER (
        input clock, reset,
        output IR, E_control, npc_out, Mem_control, W_control
    );

    modport MONITOR (
        input clock, reset,
        IR, E_control, npc_out, Mem_control, W_control
    );

endinterface