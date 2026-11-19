// Observation-only WB output agent: no driver or sequencer.
class writeback_out_agent extends uvm_agent;
  `uvm_component_utils(writeback_out_agent)

  writeback_out_configuration configuration;
  writeback_out_monitor monitor;
  uvm_analysis_port #(writeback_out_transaction) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    is_active = UVM_PASSIVE;
    analysis_port = new("analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(writeback_out_configuration)::get(
          this, "", "configuration", configuration) || configuration == null)
      `uvm_fatal("NO_CONFIG", "Writeback out agent configuration is missing or null")
    if (configuration.monitor_bfm == null)
      `uvm_fatal("NO_BFM", "Writeback out configuration has a null monitor BFM")

    // Share the configuration with the child before its build_phase.
    uvm_config_db#(writeback_out_configuration)::set(
      this, "monitor", "configuration", configuration);
    monitor = writeback_out_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    monitor.analysis_port.connect(analysis_port);
  endfunction
endclass
