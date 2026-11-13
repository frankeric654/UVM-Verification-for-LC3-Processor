class mem_access_in_monitor extends uvm_monitor;
    `uvm_component_utils(mem_access_in_monitor)

    virtual mem_access_in_monitor_bfm bfm;
    uvm_analysis_port #(mem_access_in_transaction) analysis_port;

    function new(
        string name = "mem_access_in_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        mem_access_in_transaction trans;
        bfm.wait_for_reset();
        forever begin
            trans = mem_access_in_transaction::type_id::create("trans");
            bfm.monitor(
                .mem_state_o(trans.mem_state),
                .M_Control_o(trans.M_Control),
                .M_Data_o(trans.M_Data),
                .M_Addr_o(trans.M_Addr),
                .Data_dout_o(trans.Data_dout)
            );
            analysis_port.write(trans);
        end
    endtask
endclass : mem_access_in_monitor
