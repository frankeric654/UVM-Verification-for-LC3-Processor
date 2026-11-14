interface decode_out_monitor_bfm(
    decode_out_if.MONITOR bfm
);

    // low level monitor task to sample the interface signals on each clock cycle
    task automatic monitor(
        // outputs to monitor class
        output logic [15:0] IR_o,
        output logic [15:0] npc_out_o,
        output logic [5:0]  E_control_o,
        output logic [1:0]  W_control_o,
        output logic        Mem_control_o
    );
        // loop until enable_decode is 1 after a clock edge
        // sample at posedge of clock, when enable_decode is 1
        
        @(posedge bfm.clock);
        #1step; // wait for 1 time step to ensure signals are stable
        
        
        // sample each of the decode output signals once enable_decode is 1
        IR_o          = bfm.IR;
        npc_out_o     = bfm.npc_out;
        E_control_o   = bfm.E_control;
        W_control_o   = bfm.W_control;
        Mem_control_o = bfm.Mem_control;
        // print statement to send info about the recovered signal to terminal
        $display("Decode Out Monitor BFM: IR = %h, npc_out = %h, E_control = %b, W_control = %b, Mem_control = %b",
            IR_o, npc_out_o, E_control_o, W_control_o, Mem_control_o);
        
    endtask

    task automatic wait_for_reset();
        @(negedge bfm.reset);
    endtask

endinterface