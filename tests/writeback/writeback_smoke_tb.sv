// Infrastructure self-test with a small behavioral fixture; not LC3 RTL validation.
module writeback_smoke_tb;
  timeunit 1ns;
  timeprecision 1ps;
  import uvm_pkg::*;
  import writeback_env_pkg::*;
  import writeback_in_pkg::*;
  import writeback_out_pkg::*;
  `include "uvm_macros.svh"
  bit clock = 0;
  always #5ns clock = ~clock;
  logic reset = 1, enable_writeback = 0;
  logic [1:0] W_Control = 0;
  logic [15:0] aluout, memout, pcout, npc = 0;
  logic [2:0] sr1 = 0, sr2 = 1, dr = 0;
  logic [15:0] regs[0:7];
  logic [15:0] d1, d2, selected;
  logic [2:0] psr, observed_psr;
  bit done = 0, change_address_at_edge = 0;
  bit fault_d1, fault_psr;

  // Independent fixture state; model and fixture share no register storage.
  always_comb begin
    case (W_Control)
      0: selected = aluout;
      1: selected = memout;
      2: selected = pcout;
      default: selected = 'x;
    endcase
  end
  always @(posedge clock) begin
    if (reset) psr <= 3'b010;
    else if (enable_writeback) begin
      regs[dr] <= selected;
      if (selected == 0) psr <= 3'b010;
      else if (selected[15]) psr <= 3'b100;
      else psr <= 3'b001;
    end
    // Deliberately change the address in NBA to exercise pre-edge sampling.
    if (change_address_at_edge) sr1 <= sr1 + 1'b1;
  end
  assign d1 = (fault_d1 && $time > 150) ? 16'hxxxx : regs[sr1];
  assign d2 = regs[sr2];
  assign observed_psr = (fault_psr && $time > 150) ? 3'bxxx : psr;

  writeback_in_if in_bus(clock, reset, enable_writeback, W_Control,
                         aluout, memout, pcout, npc, sr1, sr2, dr);
  writeback_out_if out_bus(clock, sr1, sr2, d1, d2, observed_psr);
  writeback_in_monitor_bfm in_bfm(in_bus);
  writeback_out_monitor_bfm out_bfm(out_bus);

  class writeback_smoke_test extends uvm_test;
    `uvm_component_utils(writeback_smoke_test)
    writeback_environment env;
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = writeback_environment::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      wait(done);
      #1ns;
      if (env.scoreboard.pairs < 50 || env.scoreboard.field_checks < 100)
        `uvm_error("WB_SELFTEST", "Insufficient samples/checks")
      phase.drop_objection(this);
    endtask
  endclass

  // Match the team's IMem/Fetch bench: active-high reset for five rising
  // edges, released in NBA so synchronous RTL still sees reset at edge five.
  // This defines stimulus timing, not the unspecified WB reset state values.
  task automatic apply_reset();
    reset = 1'b1;
    enable_writeback = 1'b0;
    repeat (5) @(posedge clock);
    reset <= 1'b0;
    @(negedge clock);
  endtask

  task automatic drive(bit en, bit [1:0] source, bit [2:0] dest,
                       bit [2:0] read1, bit [2:0] read2, logic [15:0] value);
    @(negedge clock);
    enable_writeback = en;
    W_Control = source;
    dr = dest;
    sr1 = read1;
    sr2 = read2;
    // X on unused data inputs must not contaminate a valid selected source.
    aluout = 'x; memout = 'x; pcout = 'x;
    case (source)
      0: aluout = value;
      1: memout = value;
      2: pcout = value;
    endcase
  endtask

  initial begin
    writeback_in_configuration in_cfg;
    writeback_out_configuration out_cfg;
    fault_d1 = $test$plusargs("WB_FAULT_D1");
    fault_psr = $test$plusargs("WB_FAULT_PSR");
    in_cfg = writeback_in_configuration::type_id::create("in_cfg");
    out_cfg = writeback_out_configuration::type_id::create("out_cfg");
    if (!$test$plusargs("WB_NULL_BFM")) in_cfg.monitor_bfm = in_bfm;
    out_cfg.monitor_bfm = out_bfm;
    if (!$test$plusargs("WB_MISSING_CONFIG"))
      uvm_config_db#(writeback_in_configuration)::set(
        null, "uvm_test_top.env.in_agent", "configuration", in_cfg);
    uvm_config_db#(writeback_out_configuration)::set(
      null, "uvm_test_top.env.out_agent", "configuration", out_cfg);
    run_test("writeback_smoke_test");
  end
  initial begin
    apply_reset();
    for (int source = 0; source < 3; source++) begin
      for (int i = 0; i < 8; i++) begin
        drive(1, source, i, i, 7-i, 16'(i + source*16));
        drive(0, source, i, i, 7-i, 16'hdead);
      end
    end
    drive(1, 0, 2, 2, 2, 16'hffff);
    drive(1, 1, 2, 2, 2, 16'h8000);
    drive(1, 2, 2, 2, 2, 16'h7fff);
    drive(1, 0, 2, 2, 2, 16'h0000);
    change_address_at_edge = 1;
    drive(0, 0, 0, 2, 2, 0);
    @(negedge clock);
    change_address_at_edge = 0;
    // Unknown selected write invalidates R3; a later overwrite restores it.
    drive(1, 0, 3, 3, 2, 16'hxxxx);
    drive(0, 0, 0, 3, 2, 0);
    drive(1, 1, 3, 3, 2, 16'd17);
    drive(0, 0, 0, 3, 2, 0);
    @(negedge clock);
    apply_reset();
    // Reinitialization after reset must reestablish all known values.
    for (int i = 0; i < 8; i++) drive(1, 0, i, i, 7-i, 16'(100+i));
    for (int i = 0; i < 8; i++) drive(0, 0, 0, i, 7-i, 0);
    @(negedge clock);
    done = 1;
  end
  initial begin
    #10us;
    `uvm_fatal("WB_TIMEOUT", "Self-test timed out")
  end
endmodule
