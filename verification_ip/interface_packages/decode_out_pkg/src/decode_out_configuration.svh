class decode_out_configuration extends uvm_object;

    `uvm_object_utils(decode_out_configuration)

    // handles to the HDL BFMs instantiated in hdl_top

    virtual decode_out_monitor_bfm monitor_bfm;

    // controls whether a coverage collector is instantiated in the agent
    bit coverage_enable = 1;

    // controls whether the agent creates its driver
    uvm_active_passive_enum is_active = UVM_PASSIVE;

    function new(string name = "decode_out_configuration");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf(
            "is_active: %s, monitor_bfm: %s, coverage_enable: %b",
            is_active.name(),
            (monitor_bfm == null) ? "null" : "set",
            coverage_enable
        );
    endfunction

    function void initialize(
        string parent_path,
        string name,
        uvm_active_passive_enum activity
    );
        string agent_path;

        is_active = activity;

        // Example:
        // parent_path = "uvm_test_top"
        // name        = "agent_in"
        // agent_path  = "uvm_test_top.agent_in"
        agent_path = {parent_path, ".", name};

        if (!uvm_config_db#(virtual decode_out_monitor_bfm)::get(
                null,
                agent_path,
                "monitor_bfm",
                monitor_bfm
            )) begin
            `uvm_fatal(
                "NOMONITORBFM",
                $sformatf(
                    "Could not find monitor BFM at scope '%s' with field 'monitor_bfm'",
                    agent_path
                )
            )
        end

        if (is_active != UVM_PASSIVE)
            `uvm_fatal("DECODE_OUT_ACTIVITY", "Decode output agent must be passive")

    endfunction

endclass