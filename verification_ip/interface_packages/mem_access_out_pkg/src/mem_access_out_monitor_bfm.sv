interface mem_access_out_monitor_bfm (
    mem_access_out_if.MONITOR bfm
);
    task automatic monitor(
        output logic [15:0] Data_addr_o,
        output logic [15:0] Data_din_o,
        output logic        Data_rd_o,
        output logic [15:0] memout_o
    );
        @(posedge bfm.clock);
        #0;
        Data_addr_o = bfm.Data_addr;
        Data_din_o  = bfm.Data_din;
        Data_rd_o   = bfm.Data_rd;
        memout_o    = bfm.memout;
    endtask

    task automatic wait_for_reset();
        @(negedge bfm.reset);
    endtask
endinterface
