// Include INSIDE the team's HDL top module, after its LC3 instance.
// Define WB_DUT_PATH to that LC3 instance (default: dut).
// Call configure_writeback_bfms("uvm_test_top.env.writeback_env") BEFORE run_test.
`ifndef WB_DUT_PATH
  `define WB_DUT_PATH dut
`endif
writeback_in_if wb_in_bus (
  .clock(`WB_DUT_PATH.WB.clock),
  .reset(`WB_DUT_PATH.WB.reset),
  .enable_writeback(`WB_DUT_PATH.WB.enable_writeback),
  .W_Control(`WB_DUT_PATH.WB.W_Control),
  .aluout(`WB_DUT_PATH.WB.aluout),
  .memout(`WB_DUT_PATH.WB.memout),
  .pcout(`WB_DUT_PATH.WB.pcout),
  .npc(`WB_DUT_PATH.WB.npc),
  .sr1(`WB_DUT_PATH.WB.sr1),
  .sr2(`WB_DUT_PATH.WB.sr2),
  .dr(`WB_DUT_PATH.WB.dr)
);
writeback_out_if wb_out_bus (
  .clock(`WB_DUT_PATH.WB.clock),
  .sr1(`WB_DUT_PATH.WB.sr1),
  .sr2(`WB_DUT_PATH.WB.sr2),
  .d1(`WB_DUT_PATH.WB.d1),
  .d2(`WB_DUT_PATH.WB.d2),
  .psr(`WB_DUT_PATH.WB.psr)
);
writeback_in_monitor_bfm wb_in_bfm(wb_in_bus);
writeback_out_monitor_bfm wb_out_bfm(wb_out_bus);
function void configure_writeback_bfms(string env_path);
  writeback_in_pkg::writeback_in_configuration in_cfg;
  writeback_out_pkg::writeback_out_configuration out_cfg;
  in_cfg = writeback_in_pkg::writeback_in_configuration::type_id::create("wb_in_cfg");
  out_cfg = writeback_out_pkg::writeback_out_configuration::type_id::create("wb_out_cfg");
  in_cfg.monitor_bfm = wb_in_bfm;
  out_cfg.monitor_bfm = wb_out_bfm;
  uvm_pkg::uvm_config_db#(writeback_in_pkg::writeback_in_configuration)::set(
    null, {env_path, ".in_agent"}, "configuration", in_cfg);
  uvm_pkg::uvm_config_db#(writeback_out_pkg::writeback_out_configuration)::set(
    null, {env_path, ".out_agent"}, "configuration", out_cfg);
endfunction
