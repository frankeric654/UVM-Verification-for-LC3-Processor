class control_out_agent extends uvm_agent;
    `uvm_component_utils(control_out_agent)
    control_out_configuration configuration;
    control_out_monitor monitor;
    control_out_coverage coverage;
    uvm_analysis_port #(control_out_transaction) analysis_port;

    function new(string name = "control_out_agent", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(control_out_configuration)::get(this, "", "configuration", configuration)
            || configuration == null)
            `uvm_fatal("NO_CONFIGURATION", "control_out_agent requires configuration")
        is_active = configuration.is_active;
        if (is_active != UVM_PASSIVE)
            `uvm_fatal("CONTROL_ACTIVITY", "control_out_agent must be passive")
        monitor = control_out_monitor::type_id::create("monitor", this);
        monitor.monitor_bfm = configuration.monitor_bfm;
        if (configuration.coverage_enable)
            coverage = control_out_coverage::type_id::create("coverage", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.analysis_port.connect(analysis_port);
        if (coverage != null) monitor.analysis_port.connect(coverage.analysis_export);
    endfunction
endclass
