
class execute_env extends uvm_env;

  `uvm_component_utils(execute_env)

  execute_in_agent  in_agent;
  execute_out_agent out_agent;
  execute_predictor predictor;
  execute_scoreboard scoreboard;
  execute_coverage coverage;

  // Configuration object for the Execute environment.
  execute_configuration configuration;

  function new(string name = "execute_env",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get configuration from the UVM configuration database.
    // If none was provided, create a default configuration.
    if (!uvm_config_db#(execute_configuration)::get(
          this, "", "configuration", configuration)) begin

      configuration = execute_configuration::type_id::create(
        "configuration"
      );

      `uvm_info("EXE_ENV",
        "No configuration found; using default settings",
        UVM_LOW)
    end

    // Input and output monitors are always created.
    in_agent = execute_in_agent::type_id::create(
      "in_agent", this
    );

    out_agent = execute_out_agent::type_id::create(
      "out_agent", this
    );

    // Create predictor if enabled.
    if (configuration.enable_predictor) begin
      predictor = execute_predictor::type_id::create(
        "predictor", this
      );
    end

    // Create scoreboard if enabled.
    if (configuration.enable_scoreboard) begin
      scoreboard = execute_scoreboard::type_id::create(
        "scoreboard", this
      );
    end

    // Create Execute functional coverage collector.
    coverage = execute_coverage::type_id::create(
      "coverage", this
    );

  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Input Monitor -> Predictor
    if (predictor != null) begin
      in_agent.monitor.analysis_port.connect(
        predictor.analysis_imp
      );
    end

    // Predictor -> Scoreboard (Expected)
    if ((predictor != null) && (scoreboard != null)) begin
      predictor.expected_ap.connect(
        scoreboard.expected_imp
      );
    end

    // Output Monitor -> Scoreboard (Actual)
    if (scoreboard != null) begin
      out_agent.monitor.analysis_port.connect(
        scoreboard.actual_imp
      );
    end

    // Input Monitor -> Functional Coverage
    in_agent.monitor.analysis_port.connect(
      coverage.analysis_export
    );

  endfunction

endclass

/*尚未細讀*/
