class writeback_environment extends uvm_env;
  `uvm_component_utils(writeback_environment)
  writeback_in_agent in_agent;
  writeback_out_agent out_agent;
  writeback_predictor predictor;
  writeback_scoreboard scoreboard;
  writeback_coverage coverage;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    in_agent = writeback_in_agent::type_id::create("in_agent", this);
    out_agent = writeback_out_agent::type_id::create("out_agent", this);
    predictor = writeback_predictor::type_id::create("predictor", this);
    scoreboard = writeback_scoreboard::type_id::create("scoreboard", this);
    coverage = writeback_coverage::type_id::create("coverage", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    in_agent.analysis_port.connect(predictor.analysis_export);
    in_agent.analysis_port.connect(coverage.analysis_export);
    predictor.analysis_port.connect(scoreboard.expected_export);
    out_agent.analysis_port.connect(scoreboard.actual_export);
  endfunction
endclass
