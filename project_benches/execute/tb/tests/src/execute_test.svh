
class execute_test extends uvm_test;

  `uvm_component_utils(execute_test)

  execute_env env;
  execute_configuration configuration;

  function new(
    string name = "execute_test",
    uvm_component parent = null
  );
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create Execute environment configuration.
    configuration =
      execute_configuration::type_id::create("configuration");

    configuration.enable_predictor = 1;
    configuration.enable_scoreboard = 1;

    // Provide configuration to Execute environment.
    uvm_config_db#(execute_configuration)::set(
      this,
      "env",
      "configuration",
      configuration
    );

    // Create Execute environment.
    env = execute_env::type_id::create("env", this);

  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    uvm_top.print_topology();

  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    phase.raise_objection(this);

    `uvm_info("EXE_TEST",
      "Execute test started",
      UVM_LOW)

    // Temporary placeholder until DUT stimulus is implemented.
    // Allow sufficient time for all directed and random stimulus.
    #1200;

    `uvm_info("EXE_TEST",
      "Execute test finished",
      UVM_LOW)

    phase.drop_objection(this);
  endtask

endclass
/*尚未細讀*/
