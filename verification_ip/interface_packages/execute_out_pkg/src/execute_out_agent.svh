
class execute_out_agent extends uvm_agent;

  `uvm_component_utils(execute_out_agent)

  // Passive agent: only a monitor is needed.
  execute_out_monitor monitor;

  function new(string name = "execute_out_agent",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create the monitor as a child component of this agent.
    monitor = execute_out_monitor::type_id::create("monitor", this);
  endfunction

endclass
