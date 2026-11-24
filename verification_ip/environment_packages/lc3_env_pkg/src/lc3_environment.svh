class lc3_environment extends uvm_env;

  `uvm_component_utils(lc3_environment)

  // Top-level LC3 configuration.
  lc3_env_configuration configuration;

  // Individual pipeline stage environments.
  fetch_environment      fetch_env;
  decode_environment     decode_env;
  execute_env            execute_env;
  mem_access_environment mem_access_env;
  writeback_environment  writeback_env;
  control_environment    control_env;

  // Existing instruction memory responder agent.
  imem_agent imem;

  // Configuration handle exposed to top-level tests.
  imem_configuration imem_cfg;

  function new(
    string name = "lc3_environment",
    uvm_component parent = null
  );
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get the top-level configuration.
    // Allow the test to provide its own initialized configuration.
    // Otherwise, create and initialize a default configuration.
    if (!uvm_config_db#(lc3_env_configuration)::get(
          this, "", "configuration", configuration)
          || configuration == null) begin

      configuration =
        lc3_env_configuration::type_id::create("configuration");

      configuration.initialize(get_full_name());

    end

    // Create all currently available stage environments.
    fetch_env = fetch_environment::type_id::create(
      "fetch_env", this
    );

    decode_env = decode_environment::type_id::create(
      "decode_env", this
    );

    execute_env = execute_env_pkg::execute_env::type_id::create(
      "execute_env", this
    );

    mem_access_env = mem_access_environment::type_id::create(
      "mem_access_env", this
    );

    writeback_env = writeback_environment::type_id::create(
      "writeback_env", this
    );

    control_env = control_environment::type_id::create(
      "control_env", this
    );

    // Create the existing active IMEM responder agent.
    imem = imem_agent::type_id::create(
      "imem", this
    );

    // Fetch uses UVMF configuration handling.
    fetch_env.set_config(configuration.fetch_config);

    // Decode expects the field name "config".
    uvm_config_db#(decode_env_configuration)::set(
      this,
      "decode_env",
      "config",
      configuration.decode_config
    );

    // Execute expects the field name "configuration".
    uvm_config_db#(execute_configuration)::set(
      this,
      "execute_env",
      "configuration",
      configuration.execute_config
    );

    // Memory Access expects the field name "config".
    uvm_config_db#(mem_access_env_configuration)::set(
      this,
      "mem_access_env",
      "config",
      configuration.mem_access_config
    );

    // Writeback currently has no environment configuration.
    // Pass the configurations directly to its passive agents.
    uvm_config_db#(
      writeback_in_pkg::writeback_in_configuration
    )::set(
      this,
      "writeback_env.in_agent",
      "configuration",
      configuration.writeback_in_config
    );

    uvm_config_db#(
      writeback_out_pkg::writeback_out_configuration
    )::set(
      this,
      "writeback_env.out_agent",
      "configuration",
      configuration.writeback_out_config
    );

    // Control expects the field name "configuration".
    uvm_config_db#(control_env_configuration)::set(
      this,
      "control_env",
      "configuration",
      configuration.control_config
    );

    // IMEM uses UVMF configuration handling.
    // Both handles refer to the same configuration object.
    imem_cfg = configuration.imem_cfg;

    imem.set_config(imem_cfg);

  endfunction

endclass
