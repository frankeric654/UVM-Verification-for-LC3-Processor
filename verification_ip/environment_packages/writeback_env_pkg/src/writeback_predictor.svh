// One instance only: the supplied package function owns shared static state.
class writeback_predictor extends uvm_component;
  `uvm_component_utils(writeback_predictor)
  uvm_analysis_imp #(writeback_in_transaction, writeback_predictor) analysis_export;
  uvm_analysis_port #(writeback_expected_transaction) analysis_port;
  protected bit [7:0] reg_known = '0;
  protected logic [2:0] held_psr;
  protected bit psr_known = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    analysis_port = new("analysis_port", this);
  endfunction

  function void write(writeback_in_transaction txn);
    writeback_in_transfer_t s;
    writeback_expected_transaction expected;
    bit [15:0] rd1, rd2;
    bit [2:0] model_psr;
    bit model_enable, status;
    logic [15:0] selected;
    s = txn.sample;
    expected = writeback_expected_transaction::type_id::create("expected");
    expected.edge_time_ps = txn.edge_time_ps;
    expected.sample.sr1 = s.sr1;
    expected.sample.sr2 = s.sr2;

    // Reset behavior is not specified sufficiently. Invalidate knowledge rather
    // than inventing cleared registers/PSR. Subsequent known writes revalidate.
    if (s.reset !== 1'b0) begin
      reg_known = '0;
      psr_known = 0;
      analysis_port.write(expected);
      return;
    end

    // Capture validity BEFORE this edge's write (read-before-write contract).
    expected.check_d1 = !$isunknown(s.sr1) && reg_known[s.sr1];
    expected.check_d2 = !$isunknown(s.sr2) && reg_known[s.sr2];
    selected = 'x;
    case (s.W_Control)
      2'b00: selected = s.aluout;
      2'b01: selected = s.memout;
      2'b10: selected = s.pcout;
      default: ; // 11/X selection has no defined source in the supplied model.
    endcase
    model_enable = (s.enable_writeback === 1'b1) &&
                   !$isunknown({s.dr, s.W_Control, selected});
    // Unused X inputs may safely coerce to bit; they cannot affect the selected
    // source. Unknown read addresses have their corresponding checks disabled.
    status = lc3_prediction_pkg::writeback_model(
      s.aluout, s.W_Control, s.npc, s.pcout, s.memout,
      model_enable, s.sr1, s.sr2, s.dr, rd1, rd2, model_psr);
    if (status) `uvm_fatal("WB_MODEL", "Supplied WB model reported failure")
    expected.sample.d1 = rd1;
    expected.sample.d2 = rd2;

    if (model_enable) begin
      reg_known[s.dr] = 1;
      held_psr = model_psr;
      psr_known = 1;
    end else if (s.enable_writeback !== 1'b0) begin
      // An ambiguous write can affect the addressed register and PSR. The
      // model's stale contents remain masked until a known overwrite occurs.
      if ($isunknown(s.dr)) reg_known = '0;
      else reg_known[s.dr] = 0;
      psr_known = 0;
      `uvm_warning("WB_UNDEFINED_WRITE", "Unknown/unsupported write: checks invalidated")
    end
    expected.sample.psr = held_psr;
    expected.check_psr = psr_known;
    analysis_port.write(expected);
  endfunction
endclass
