class control_environment extends uvm_env;
    `uvm_component_utils(control_environment)
    control_env_configuration configuration;
    control_in_pkg::control_in_agent control_in_agent;
    control_out_pkg::control_out_agent control_out_agent;
    control_predictor predictor;
    control_scoreboard scoreboard;
    control_memory_coverage memory_coverage;

    function new(string name = "control_environment", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(control_env_configuration)::get(this, "", "configuration", configuration)
            || configuration == null)
            `uvm_fatal("NO_CONFIGURATION", "control_environment requires configuration")
        control_in_agent = control_in_pkg::control_in_agent::type_id::create("control_in_agent", this);
        control_out_agent = control_out_pkg::control_out_agent::type_id::create("control_out_agent", this);
        predictor = control_predictor::type_id::create("predictor", this);
        predictor.reset_enable_fetch = configuration.reset_enable_fetch;
        scoreboard = control_scoreboard::type_id::create("scoreboard", this);
        memory_coverage = control_memory_coverage::type_id::create("memory_coverage", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        control_in_agent.analysis_port.connect(predictor.analysis_export);
        predictor.analysis_port.connect(scoreboard.expected_export);
        control_out_agent.analysis_port.connect(scoreboard.actual_export);
        control_in_agent.analysis_port.connect(memory_coverage.control_in_export);
        control_out_agent.analysis_port.connect(memory_coverage.control_out_export);
    endfunction
endclass
