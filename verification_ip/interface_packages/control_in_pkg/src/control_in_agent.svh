class control_in_agent extends uvm_agent;
    `uvm_component_utils(control_in_agent)
    control_in_configuration configuration;
    control_in_monitor monitor;
    control_in_coverage coverage;
    uvm_analysis_port #(control_in_transaction) analysis_port;

    function new(string name = "control_in_agent", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(control_in_configuration)::get(this, "", "configuration", configuration)
            || configuration == null)
            `uvm_fatal("NO_CONFIGURATION", "control_in_agent requires configuration")
        is_active = configuration.is_active;
        if (is_active != UVM_PASSIVE)
            `uvm_fatal("CONTROL_ACTIVITY", "control_in_agent must be passive")
        monitor = control_in_monitor::type_id::create("monitor", this);
        monitor.monitor_bfm = configuration.monitor_bfm;
        if (configuration.coverage_enable)
            coverage = control_in_coverage::type_id::create("coverage", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        monitor.analysis_port.connect(analysis_port);
        if (coverage != null) monitor.analysis_port.connect(coverage.analysis_export);
    endfunction
endclass
