// Plain UVM configuration for the passive WB in agent.
class writeback_in_configuration extends uvm_object;
  `uvm_object_utils(writeback_in_configuration)

  // Handle to an existing HDL instance; this does not create the BFM.
  virtual writeback_in_monitor_bfm monitor_bfm;

  function new(string name = "writeback_in_configuration");
    super.new(name);
  endfunction
endclass
