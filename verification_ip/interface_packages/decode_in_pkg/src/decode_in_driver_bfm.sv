interface decode_in_driver_bfm (
    decode_in_if.DRIVER bfm
);
    // delay until reset asserted
    task automatic wait_for_reset();
        @(negedge bfm.reset);
    endtask
    // task to drive the inputs to the bfm interface
    task automatic drive(
        input logic        enable_decode_i,
        input logic [15:0] IMem_dout_i,
        input logic [15:0] npc_in_i
    );
        // update values on falling edge of the clock
        @(negedge bfm.clock);
        bfm.enable_decode <= enable_decode_i;
        bfm.IMem_dout     <= IMem_dout_i;
        bfm.npc_in        <= npc_in_i;
    endtask

endinterface