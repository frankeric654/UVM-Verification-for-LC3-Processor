// Passive WB input monitor; sampling is added in the following step.
class writeback_in_monitor extends uvm_monitor;
  `uvm_component_utils(writeback_in_monitor)

  virtual writeback_in_monitor_bfm bfm;
  uvm_analysis_port #(writeback_in_transaction) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual writeback_in_monitor_bfm)::get(
          this, "", "bfm", bfm) || bfm == null)
      `uvm_fatal("NO_BFM", "Writeback input BFM is missing or null")
  endfunction
endclass
