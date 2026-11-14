class control_in_monitor extends uvm_monitor;
    `uvm_component_utils(control_in_monitor)
    virtual control_in_monitor_bfm monitor_bfm;
    uvm_analysis_port #(control_in_transaction) analysis_port;

    function new(string name = "control_in_monitor", uvm_component parent = null);
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
                                            logic complete_data,
                                            logic complete_instr,
                                            logic [15:0] IR,
                                            logic [15:0] IR_Exec,
                                            logic [15:0] Instr_dout,
                                            logic [2:0] NZP,
                                            logic [2:0] psr);
        control_in_transaction t = control_in_transaction::type_id::create("observed");
        t.cycle = cycle;
        t.sample_time = $time;
        t.reset = reset;
        t.complete_data = complete_data;
        t.complete_instr = complete_instr;
        t.IR = IR;
        t.IR_Exec = IR_Exec;
        t.Instr_dout = Instr_dout;
        t.NZP = NZP;
        t.psr = psr;
        analysis_port.write(t);
    endfunction
endclass
