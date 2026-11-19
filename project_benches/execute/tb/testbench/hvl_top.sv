module hvl_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import execute_in_pkg::*;
  import execute_out_pkg::*;
  import lc3_prediction_pkg::*;
  import execute_env_pkg::*;
  import execute_test_pkg::*;

  initial begin

    // Provide the input monitor BFM to the UVM input monitor.
    uvm_config_db#(virtual execute_in_monitor_bfm)::set(
      null,
      "uvm_test_top.env.in_agent.monitor",
      "monitor_bfm",
      $root.hdl_top.in_monitor_bfm
    );

    // Provide the output monitor BFM to the UVM output monitor.
    uvm_config_db#(virtual execute_out_monitor_bfm)::set(
      null,
      "uvm_test_top.env.out_agent.monitor",
      "monitor_bfm",
      $root.hdl_top.out_monitor_bfm
    );

    // Start the UVM test.
    run_test("execute_test");

  end

endmodule
/*尚未細讀*/
