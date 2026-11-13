interface mem_access_in_monitor_bfm (
    mem_access_in_if.MONITOR bfm
);
    task automatic monitor(
        output logic [1:0]  mem_state_o,
        output logic        M_Control_o,
        output logic [15:0] M_Data_o,
        output logic [15:0] M_Addr_o,
        output logic [15:0] Data_dout_o
    );
        @(posedge bfm.clock);
        #0;
        mem_state_o = bfm.mem_state;
        M_Control_o = bfm.M_Control;
        M_Data_o    = bfm.M_Data;
        M_Addr_o    = bfm.M_Addr;
        Data_dout_o = bfm.Data_dout;
    endtask

    task automatic wait_for_reset();
        @(negedge bfm.reset);
    endtask
endinterface