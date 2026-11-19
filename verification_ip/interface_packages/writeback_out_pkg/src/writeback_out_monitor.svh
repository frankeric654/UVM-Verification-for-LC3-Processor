// Passive WB output monitor: publish a fresh transaction for each sampled edge.
class writeback_out_monitor extends uvm_monitor;
  `uvm_component_utils(writeback_out_monitor)

  writeback_out_configuration configuration;
  virtual writeback_out_monitor_bfm bfm;
  uvm_analysis_port #(writeback_out_transaction) analysis_port;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(writeback_out_configuration)::get(
          this, "", "configuration", configuration) || configuration == null)
      `uvm_fatal("NO_CONFIG", "Writeback out monitor configuration is missing or null")
    bfm = configuration.monitor_bfm;
    if (bfm == null)
      `uvm_fatal("NO_BFM", "Writeback out configuration has a null monitor BFM")
  endfunction
  
  task run_phase(uvm_phase phase);
    writeback_out_transfer_t observed;
    writeback_out_transaction txn;
    time edge_time_ps;

    forever begin
      bfm.monitor(observed, edge_time_ps);
      txn = writeback_out_transaction::type_id::create("txn");
      txn.sample = observed;
      txn.edge_time_ps = edge_time_ps;
      analysis_port.write(txn);
    end
  endtask
endclass
