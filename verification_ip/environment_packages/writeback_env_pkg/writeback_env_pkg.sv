package writeback_env_pkg;
  import uvm_pkg::*;
  import lc3_prediction_pkg::*;
  import writeback_in_types_pkg::*;
  import writeback_out_types_pkg::*;
  import writeback_in_pkg::*;
  import writeback_out_pkg::*;
  `include "uvm_macros.svh"
  `include "writeback_expected_transaction.svh"
  `include "writeback_predictor.svh"
  `include "writeback_scoreboard.svh"
  `include "writeback_coverage.svh"
  `include "writeback_environment.svh"
endpackage
