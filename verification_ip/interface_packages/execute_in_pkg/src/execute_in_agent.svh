class execute_in_agent extends uvm_agent;

  `uvm_component_utils(execute_in_agent)

  // Passive agent: only a monitor is needed.
  execute_in_monitor monitor;

  function new(string name = "execute_in_agent",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create the monitor as a child component of this agent.
    monitor = execute_in_monitor::type_id::create("monitor", this);
  endfunction

endclass
/*Agent 沒有 run_phase() 因為 Agent 自己不需要持續執行任何工作。*/
/*Agent 負責建立和管理 Monitor；
Monitor 負責收集並發送 Transaction；
BFM 才是實際取樣硬體訊號的地方*/