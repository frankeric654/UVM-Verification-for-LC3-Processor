// models the input interface between the DUT and the testbench
interface decode_in_if (
    // signals
    input logic clock,
    input logic reset
    );

    // inputs
    logic           enable_decode;
    logic [15:0]    IMem_dout;
    logic [15:0]    npc_in;
   

    modport DUT (
        input clock, reset, 
        enable_decode, npc_in, IMem_dout
    );

    modport DRIVER (
        input clock, reset,
        output enable_decode, npc_in, IMem_dout
    );

    modport MONITOR (
        input clock, reset,
        enable_decode, npc_in, IMem_dout
    );

endinterface