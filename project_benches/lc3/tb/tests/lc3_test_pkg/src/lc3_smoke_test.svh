// Integration smoke only, not coverage closure or architectural retirement proof.
class lc3_smoke_test extends uvm_test;
  `uvm_component_utils(lc3_smoke_test)
  lc3_environment env;
  int unsigned cycles = 300;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'($value$plusargs("LC3_CYCLES=%d", cycles));
    if (cycles < 30) `uvm_fatal("LC3_CYCLES", "Use at least 30 cycles")
    env = lc3_environment::type_id::create("env", this);
  endfunction
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
  task run_phase(uvm_phase phase);
    imem_responder_sequence seq;
    phase.raise_objection(this);
    seq = imem_responder_sequence::type_id::create("seq");
    seq.no_repeat = 0;
    seq.stop_after_passes = 0;
    fork
      seq.start(env.imem.sequencer);
    join_none
    env.imem_cfg.wait_for_reset();
    env.imem_cfg.wait_for_num_clocks(cycles);
    // Finish away from the rising-edge and falling-edge monitor callbacks.
    #2ns;
    `uvm_info("LC3_SMOKE", $sformatf("Completed %0d clocks; imem responses=%0d",
      cycles, env.imem.monitor.responses_observed), UVM_LOW)
    phase.drop_objection(this);
  endtask
  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    `uvm_info("LC3_ACTIVITY", $sformatf(
      "fetch=%0d decode=%0d execute=%0d mem_access=%0d writeback=%0d control=%0d",
      env.fetch_env.fetch_sb.match_count + env.fetch_env.fetch_sb.mismatch_count,
      env.decode_env.scoreboard.comparison_count, env.execute_env.scoreboard.actual_count,
      env.mem_access_env.scoreboard.comparison_count, env.writeback_env.scoreboard.pairs,
      env.control_env.scoreboard.comparison_count), UVM_LOW)
    if ((env.fetch_env.fetch_sb.match_count + env.fetch_env.fetch_sb.mismatch_count) == 0 ||
        env.decode_env.scoreboard.comparison_count == 0 ||
        env.execute_env.scoreboard.actual_count == 0 ||
        env.mem_access_env.scoreboard.comparison_count == 0 ||
        env.writeback_env.scoreboard.pairs == 0 ||
        env.control_env.scoreboard.comparison_count == 0)
      `uvm_error("LC3_NO_ACTIVITY", "At least one stage comparison path has no activity")
    if (env.imem.monitor.responses_observed == 0)
      `uvm_error("LC3_NO_ACTIVITY", "Instruction responder observed no responses")
  endfunction
endclass
