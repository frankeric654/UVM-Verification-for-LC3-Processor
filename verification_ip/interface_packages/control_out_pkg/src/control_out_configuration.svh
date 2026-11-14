class control_out_configuration extends uvm_object;
    `uvm_object_utils(control_out_configuration)
    virtual control_out_monitor_bfm monitor_bfm;
    uvm_active_passive_enum is_active = UVM_PASSIVE;
    bit coverage_enable = 1;

    function new(string name = "control_out_configuration");
        super.new(name);
    endfunction

    function void initialize(string agent_path, string interface_name,
                             uvm_active_passive_enum activity = UVM_PASSIVE);
        is_active = activity;
        if (is_active != UVM_PASSIVE)
            `uvm_fatal("CONTROL_ACTIVITY", "control_out_agent must be passive in the LC3 bench")
        if (!uvm_config_db#(virtual control_out_monitor_bfm)::get(
                null, interface_name, "monitor_bfm", monitor_bfm) || monitor_bfm == null)
            `uvm_fatal("NO_MONITOR_BFM", {"Missing control_out BFM: ", interface_name})
        uvm_config_db#(control_out_configuration)::set(null, agent_path, "configuration", this);
    endfunction
endclass
