class control_out_monitor extends uvm_monitor;
    `uvm_component_utils(control_out_monitor)
    virtual control_out_monitor_bfm monitor_bfm;
    uvm_analysis_port #(control_out_transaction) analysis_port;

    function new(string name = "control_out_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        if (monitor_bfm == null) `uvm_fatal("NO_MONITOR_BFM", "Control monitor has no BFM")
        monitor_bfm.monitor = this;
    endfunction

    virtual task run_phase(uvm_phase phase);
        monitor_bfm.start_monitoring();
    endtask

    virtual function void notify_transaction(longint unsigned cycle, logic reset,
                                            logic enable_updatePC,
                                            logic enable_fetch,
                                            logic enable_decode,
                                            logic enable_execute,
                                            logic enable_writeback,
                                            logic bypass_alu_1,
                                            logic bypass_alu_2,
                                            logic bypass_mem_1,
                                            logic bypass_mem_2,
                                            logic [1:0] mem_state,
                                            logic br_taken);
        control_out_transaction t = control_out_transaction::type_id::create("observed");
        t.cycle = cycle;
        t.sample_time = $time;
        t.reset = reset;
        t.enable_updatePC = enable_updatePC;
        t.enable_fetch = enable_fetch;
        t.enable_decode = enable_decode;
        t.enable_execute = enable_execute;
        t.enable_writeback = enable_writeback;
        t.bypass_alu_1 = bypass_alu_1;
        t.bypass_alu_2 = bypass_alu_2;
        t.bypass_mem_1 = bypass_mem_1;
        t.bypass_mem_2 = bypass_mem_2;
        t.mem_state = mem_state;
        t.br_taken = br_taken;
        analysis_port.write(t);
    endfunction
endclass
