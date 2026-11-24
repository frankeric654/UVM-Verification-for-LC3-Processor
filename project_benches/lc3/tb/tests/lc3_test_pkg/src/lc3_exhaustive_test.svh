
class lc3_exhaustive_test extends lc3_smoke_test;
  `uvm_component_utils(lc3_exhaustive_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    uvm_config_db #(bit [2:0])::set(
      this, "*", "imem_cov_required_families", 3'b111);
    super.build_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    imem_responder_sequence seq;
    int unsigned drain_goal;

    phase.raise_objection(this);

    seq = imem_responder_sequence::type_id::create("seq");
    seq.no_repeat = 1;
    seq.stop_after_passes = 1;

    fork
      seq.start(env.imem.sequencer);
    join_none

    env.imem_cfg.wait_for_reset();

    fork : completion_watch
      begin
        env.imem_cfg.wait_for_num_clocks(cycles);
        `uvm_fatal("ENUM_TIMEOUT",
          "Exhaustive stimulus or drain did not complete")
      end
      begin
        wait (seq.targets_done);

        // Deliver additional legal fillers after the final target.
        drain_goal = seq.fillers_delivered + 16;
        wait (seq.fillers_delivered >= drain_goal);

        #2ns;
      end
    join_any
    disable completion_watch;

    if (seq.expected_target_count() != 37960 ||
        seq.targets_delivered != 37960 ||
        seq.passes_done != 1)
      `uvm_fatal("ENUM_COUNT",
        "Incorrect exhaustive stimulus accounting")

    `uvm_info("LC3_ENUM_DONE",
      $sformatf(
        "expected=%0d delivered=%0d passes=%0d observed=%0d protocol_errors=%0d digest=%016h",
        seq.expected_target_count(),
        seq.targets_delivered,
        seq.passes_done,
        env.imem.monitor.responses_observed,
        env.imem.monitor.protocol_errors,
        env.imem.monitor.stream_digest),
      UVM_LOW)

    phase.drop_objection(this);
  endtask
endclass
