
class execute_out_monitor extends uvm_monitor;

  `uvm_component_utils(execute_out_monitor)

  // Virtual interface to the passive monitor BFM.
  virtual execute_out_monitor_bfm monitor_bfm;

  // Broadcast observed Execute output transactions.
  uvm_analysis_port #(execute_out_transaction) analysis_port;

  function new(string name = "execute_out_monitor",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    analysis_port = new("analysis_port", this);

    if (!uvm_config_db#(virtual execute_out_monitor_bfm)::get(
          this, "", "monitor_bfm", monitor_bfm)) begin
      `uvm_fatal("EXE_OUT_MON", "Failed to get execute_out_monitor_bfm")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    execute_out_transaction tx;

    forever begin
      tx = execute_out_transaction::type_id::create("tx");
      monitor_bfm.monitor(tx.sample);
      analysis_port.write(tx);
    end
  endtask

endclass
