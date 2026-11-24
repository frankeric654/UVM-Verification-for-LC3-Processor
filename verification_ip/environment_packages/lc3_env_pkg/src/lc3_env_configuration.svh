class lc3_env_configuration extends uvm_object;

  `uvm_object_utils(lc3_env_configuration)

  // Configuration objects for individual pipeline stages.
  fetch_env_configuration      fetch_config;
  decode_env_configuration     decode_config;
  execute_configuration        execute_config;
  mem_access_env_configuration mem_access_config;
  control_env_configuration    control_config;

  // Writeback uses separate agent-level configurations.
  writeback_in_pkg::writeback_in_configuration
    writeback_in_config;

  writeback_out_pkg::writeback_out_configuration
    writeback_out_config;

  // Configuration for the existing instruction memory responder.
  imem_configuration imem_cfg;

  function new(string name = "lc3_env_configuration");
    super.new(name);

    // Create each stage configuration through the UVM factory.
    // Only create configurations owned by this LC3 configuration.
    // Other stage configurations are retrieved from config_db.

    fetch_config =
      fetch_env_configuration::type_id::create("fetch_config");

    execute_config =
      execute_configuration::type_id::create("execute_config");

    imem_cfg =
      imem_configuration::type_id::create("imem_cfg");

  endfunction

  // Initialize the configurations for the full LC3 testbench.
  function void initialize(
    string environment_path,
    string fetch_in_interface_name = "lc3_fetch_in",
    string fetch_out_interface_name = "lc3_fetch_out",
    string imem_interface_name = "lc3_imem"
  );

    string fetch_interface_names[];
    uvmf_active_passive_t fetch_interface_activity[];

    // Initialize Fetch using the UVMF configuration API.
    fetch_interface_names = new[2];
    fetch_interface_names[0] = fetch_in_interface_name;
    fetch_interface_names[1] = fetch_out_interface_name;

    fetch_interface_activity = new[2];
    fetch_interface_activity[0] = uvmf_base_pkg::PASSIVE;
    fetch_interface_activity[1] = uvmf_base_pkg::PASSIVE;

    fetch_config.initialize(
      uvmf_base_pkg::NA,
      {environment_path, ".fetch_env"},
      fetch_interface_names,
      null,
      fetch_interface_activity
    );

    // Initialize Decode as a passive stage environment.
    // Retrieve the configuration already initialized by HDL Top.
    if (!uvm_config_db#(decode_env_configuration)::get(
          null,
          {environment_path, ".decode_env"},
          "config",
          decode_config
        ) || decode_config == null) begin
      `uvm_fatal("LC3_DECODE_CONFIG",
        "Missing Decode environment configuration")
    end

    // Execute monitors retrieve their BFMs directly from config_db.
    // No additional environment configuration initialization is required.

    // Initialize Memory Access as a passive stage environment.
    // Retrieve the configuration already initialized by HDL Top.
    if (!uvm_config_db#(mem_access_env_configuration)::get(
          null,
          {environment_path, ".mem_access_env"},
          "config",
          mem_access_config
        ) || mem_access_config == null) begin
      `uvm_fatal("LC3_MEM_CONFIG",
        "Missing Memory Access environment configuration")
    end

    // Retrieve the Writeback input monitor BFM.
    // The BFM is already stored in the existing agent configuration.
    if (!uvm_config_db#(
          writeback_in_pkg::writeback_in_configuration
        )::get(
          null,
          {environment_path, ".writeback_env.in_agent"},
          "configuration",
          writeback_in_config
        ) || writeback_in_config == null) begin
      `uvm_fatal("LC3_WB_IN_CONFIG",
        "Missing Writeback input configuration")
    end

    if (writeback_in_config.monitor_bfm == null) begin
      `uvm_fatal("LC3_WB_IN_BFM",
        "Missing Writeback input monitor BFM")
    end

    // Retrieve the Writeback output monitor BFM.
    // The BFM is already stored in the existing agent configuration.
    if (!uvm_config_db#(
          writeback_out_pkg::writeback_out_configuration
        )::get(
          null,
          {environment_path, ".writeback_env.out_agent"},
          "configuration",
          writeback_out_config
        ) || writeback_out_config == null) begin
      `uvm_fatal("LC3_WB_OUT_CONFIG",
        "Missing Writeback output configuration")
    end

    if (writeback_out_config.monitor_bfm == null) begin
      `uvm_fatal("LC3_WB_OUT_BFM",
        "Missing Writeback output monitor BFM")
    end

    // Initialize the passive Control environment.
    // Retrieve the configuration already initialized by HDL Top.
    if (!uvm_config_db#(control_env_configuration)::get(
          null,
          {environment_path, ".control_env"},
          "configuration",
          control_config
        ) || control_config == null) begin
      `uvm_fatal("LC3_CONTROL_CONFIG",
        "Missing Control environment configuration")
    end

    // Initialize the existing IMEM agent as an active responder.
    imem_cfg.initialize(
      uvmf_base_pkg::ACTIVE,
      {environment_path, ".imem"},
      imem_interface_name
    );

    imem_cfg.initiator_responder =
      uvmf_base_pkg::RESPONDER;

  endfunction

endclass
