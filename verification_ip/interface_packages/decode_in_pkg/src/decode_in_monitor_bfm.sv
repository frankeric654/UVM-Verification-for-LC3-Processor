interface decode_in_monitor_bfm (
    decode_in_if.MONITOR bfm
);
    // low level monitor task to sample the interface signals on each clock cycle
    task automatic monitor(
        // outputs to go to monitor class
        output logic        enable_decode_o,
        output logic [15:0] IMem_dout_o,
        output logic [15:0] npc_in_o
    );
        // grab signals on the rising edge of the clock
        @(posedge bfm.clock);

        enable_decode_o = bfm.enable_decode;
        IMem_dout_o     = bfm.IMem_dout;
        npc_in_o        = bfm.npc_in;
        // print statement to send info about the recovered signal to terminal
        $display("Decode In Monitor BFM: enable_decode = %b, IMem_dout = %h, npc_in = %h", 
            enable_decode_o, IMem_dout_o, npc_in_o);
    endtask

    // delay until reset asserted
    task automatic wait_for_reset();
        @(negedge bfm.reset);
    endtask

endinterface