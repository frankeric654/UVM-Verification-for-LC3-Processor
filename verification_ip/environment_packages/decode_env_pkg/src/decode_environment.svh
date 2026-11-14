class decode_environment extends uvm_env;

    `uvm_component_utils(decode_environment);

    decode_in_agent   agent_in;
    decode_out_agent  agent_out;
    decode_predictor  predictor;
    decode_scoreboard scoreboard;
    decode_env_configuration env_config;

    function new(string name = "decode_environment", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // constructs agents, predictor, scoreboard
        agent_in =          decode_in_agent::type_id::create("agent_in", this);
        agent_out =         decode_out_agent::type_id::create("agent_out", this);
        predictor =  decode_predictor::type_id::create("predictor", this);
        scoreboard = decode_scoreboard::type_id::create("scoreboard", this);

        // get configuration object from config database
        if (!uvm_config_db#(decode_env_configuration)::get(
                this, "", "config", env_config
            )) begin
            `uvm_fatal("NOCONFIG", "Missing decode environment configuration")
        end

        // pass configuration to the agents
        uvm_config_db#(decode_in_configuration)::set(
            this, "agent_in", "config", env_config.config_in
        );
        uvm_config_db#(decode_out_configuration)::set(
            this, "agent_out", "config", env_config.config_out
        );
       
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // connections
        agent_in.monitor_ap.connect(predictor.analysis_export);
        predictor.predictor_ap.connect(scoreboard.expected_export);
        agent_out.monitor_ap.connect(scoreboard.actual_export);
    endfunction

    

    // connects decode_in agent to predictor
    // predictor to scoreboard
    // decode out agent to scoreboard

endclass