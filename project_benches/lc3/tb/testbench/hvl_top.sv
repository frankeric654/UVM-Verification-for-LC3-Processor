// UVM entry point; HDL instances live in hdl_top.
module hvl_top;
  import uvm_pkg::*;
  import lc3_test_pkg::*;
  initial begin
    $timeformat(-9, 3, " ns", 12);
    $root.hdl_top.configure_bfms();
    run_test(); // Default supplied by +UVM_TESTNAME=lc3_smoke_test.
  end
endmodule
