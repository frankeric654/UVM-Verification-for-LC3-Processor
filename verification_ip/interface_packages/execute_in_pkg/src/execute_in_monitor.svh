
class execute_in_monitor extends uvm_monitor;

  `uvm_component_utils(execute_in_monitor)

  // Virtual interface to the passive monitor BFM. 
  /*bfm是interface type是靜態, monitor是class type是動態所以要virtual
  Virtual Interface 讓 UVM Class 能夠存取已建立的硬體 Interface Instance
  而不需要（也不能在 Class 內直接）建立新的 Interface Instance*/
  virtual execute_in_monitor_bfm monitor_bfm;

  // Broadcast observed Execute input transactions.
  uvm_analysis_port #(execute_in_transaction) analysis_port;

  function new(string name = "execute_in_monitor",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

/*parent沒宣告virtual function:
parent handle指向child object會執行parent function */
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    analysis_port = new("analysis_port", this);

    if (!uvm_config_db#(virtual execute_in_monitor_bfm)::get(
          this, "", "monitor_bfm", monitor_bfm)) begin
      `uvm_fatal("EXE_MON", "Failed to get execute_in_monitor_bfm")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    execute_in_transaction tx;

    forever begin
      tx = execute_in_transaction::type_id::create("tx");

      monitor_bfm.monitor(tx.sample);

      analysis_port.write(tx);
    end
  endtask

endclass
/*Monitor all clock cycles, including reset and disabled cycles,
so the predictor can track reset and pipeline stall behavior.
給predictor判斷*/