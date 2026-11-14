class mem_access_out_monitor extends uvm_monitor;
    `uvm_component_utils(mem_access_out_monitor)

    virtual mem_access_out_monitor_bfm bfm;
    uvm_analysis_port #(mem_access_out_transaction) analysis_port;

    function new(
        string name = "mem_access_out_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        mem_access_out_transaction trans;
        bfm.wait_for_reset();
        forever begin
            trans = mem_access_out_transaction::type_id::create("trans");
            bfm.monitor(
                .Data_addr_o(trans.Data_addr),
                .Data_din_o(trans.Data_din),
                .Data_rd_o(trans.Data_rd),
                .memout_o(trans.memout)
            );
            analysis_port.write(trans);
        end
    endtask
endclass : mem_access_out_monitor
