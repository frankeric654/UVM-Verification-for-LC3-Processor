class mem_access_environment extends uvm_env;
    `uvm_component_utils(mem_access_environment)

    mem_access_in_agent agent_in;
    mem_access_out_agent agent_out;
    mem_access_predictor predictor;
    mem_access_scoreboard scoreboard;
    mem_access_env_configuration env_config;

    function new(
        string name = "mem_access_environment",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent_in = mem_access_in_agent::type_id::create("agent_in", this);
        agent_out = mem_access_out_agent::type_id::create("agent_out", this);
        predictor = mem_access_predictor::type_id::create("predictor", this);
        scoreboard = mem_access_scoreboard::type_id::create("scoreboard", this);

        if (!uvm_config_db#(mem_access_env_configuration)::get(
                this, "", "config", env_config
            )) begin
            `uvm_fatal("NOCONFIG", "Missing mem access environment configuration")
        end

        uvm_config_db#(mem_access_in_configuration)::set(
            this, "agent_in", "config", env_config.config_in
        );
        uvm_config_db#(mem_access_out_configuration)::set(
            this, "agent_out", "config", env_config.config_out
        );
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent_in.monitor_ap.connect(predictor.analysis_export);
        predictor.predictor_ap.connect(scoreboard.expected_export);
        agent_out.monitor_ap.connect(scoreboard.actual_export);
    endfunction
endclass : mem_access_environment
