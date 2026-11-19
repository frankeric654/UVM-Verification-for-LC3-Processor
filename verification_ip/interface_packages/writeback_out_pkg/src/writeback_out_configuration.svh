// Plain UVM configuration for the passive WB out agent.
class writeback_out_configuration extends uvm_object;
  `uvm_object_utils(writeback_out_configuration)

  // Handle to an existing HDL instance; this does not create the BFM.
  virtual writeback_out_monitor_bfm monitor_bfm;

  function new(string name = "writeback_out_configuration");
    super.new(name);
  endfunction
endclass
