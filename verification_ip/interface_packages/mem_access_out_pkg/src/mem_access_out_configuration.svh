class mem_access_out_configuration extends uvm_object;
    `uvm_object_utils(mem_access_out_configuration)

    virtual mem_access_out_monitor_bfm monitor_bfm;
    bit coverage_enable = 1;
    uvm_active_passive_enum is_active = UVM_PASSIVE;

    function new(string name = "mem_access_out_configuration");
        super.new(name);
    endfunction

    function void initialize(
        string parent_path,
        string name,
        uvm_active_passive_enum activity
    );
        string agent_path = {parent_path, ".", name};
        is_active = activity;
        if (!uvm_config_db#(virtual mem_access_out_monitor_bfm)::get(
                null, agent_path, "monitor_bfm", monitor_bfm
            )) begin
            `uvm_fatal("NOMONITORBFM", $sformatf(
                "Could not find monitor BFM at scope '%s'", agent_path))
        end
    endfunction
endclass
