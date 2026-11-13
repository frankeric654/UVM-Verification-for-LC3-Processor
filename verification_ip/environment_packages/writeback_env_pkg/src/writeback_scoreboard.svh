`uvm_analysis_imp_decl(_wb_expected)
`uvm_analysis_imp_decl(_wb_actual)
class writeback_scoreboard extends uvm_component;
  `uvm_component_utils(writeback_scoreboard)
  uvm_analysis_imp_wb_expected #(writeback_expected_transaction, writeback_scoreboard) expected_export;
  uvm_analysis_imp_wb_actual #(writeback_out_transaction, writeback_scoreboard) actual_export;
  protected writeback_expected_transaction expected_by_edge[time];
  protected writeback_out_transaction actual_by_edge[time];
  protected bit expected_seen[time], actual_seen[time];
  int unsigned pairs, field_checks, mismatches, unchecked_pairs;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_export = new("expected_export", this);
    actual_export = new("actual_export", this);
  endfunction

  function void write_wb_expected(writeback_expected_transaction txn);
    writeback_expected_transaction snapshot;
    if (expected_seen.exists(txn.edge_time_ps)) begin
      `uvm_error("WB_DUPLICATE", "Duplicate expected edge")
      return;
    end
    expected_seen[txn.edge_time_ps] = 1;
    if (!$cast(snapshot, txn.clone())) `uvm_fatal("WB_CLONE", "Expected clone failed")
    expected_by_edge[txn.edge_time_ps] = snapshot;
    compare_edge(txn.edge_time_ps);
  endfunction

  function void write_wb_actual(writeback_out_transaction txn);
    writeback_out_transaction snapshot;
    if (actual_seen.exists(txn.edge_time_ps)) begin
      `uvm_error("WB_DUPLICATE", "Duplicate actual edge")
      return;
    end
    actual_seen[txn.edge_time_ps] = 1;
    if (!$cast(snapshot, txn.clone())) `uvm_fatal("WB_CLONE", "Actual clone failed")
    actual_by_edge[txn.edge_time_ps] = snapshot;
    compare_edge(txn.edge_time_ps);
  endfunction

  function void compare_edge(time edge_ps);
    writeback_expected_transaction e;
    writeback_out_transaction a;
    bit bad;
    if (!expected_by_edge.exists(edge_ps) || !actual_by_edge.exists(edge_ps)) return;
    e = expected_by_edge[edge_ps];
    a = actual_by_edge[edge_ps];
    pairs++;
    bad = (e.sample.sr1 !== a.sample.sr1) || (e.sample.sr2 !== a.sample.sr2);
    if (e.check_d1) begin
      field_checks++;
      bad |= (e.sample.d1 !== a.sample.d1);
    end
    if (e.check_d2) begin
      field_checks++;
      bad |= (e.sample.d2 !== a.sample.d2);
    end
    if (e.check_psr) begin
      field_checks++;
      bad |= (e.sample.psr !== a.sample.psr);
    end
    if (!(e.check_d1 || e.check_d2 || e.check_psr)) unchecked_pairs++;
    if (bad) begin
      mismatches++;
      `uvm_error("WB_MISMATCH", $sformatf(
        "edge=%0d ps mask(d1,d2,psr)=%b%b%b expected=%h actual=%h",
        edge_ps, e.check_d1, e.check_d2, e.check_psr, e.sample, a.sample))
    end
    expected_by_edge.delete(edge_ps);
    actual_by_edge.delete(edge_ps);
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected_by_edge.num() || actual_by_edge.num())
      `uvm_error("WB_PENDING", $sformatf("Unpaired expected=%0d actual=%0d",
                 expected_by_edge.num(), actual_by_edge.num()))
    if (pairs == 0 || field_checks == 0)
      `uvm_error("WB_NO_CHECKS", "No meaningful WB comparisons completed")
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("WB_SUMMARY", $sformatf(
      "pairs=%0d field_checks=%0d mismatches=%0d unchecked_pairs=%0d",
      pairs, field_checks, mismatches, unchecked_pairs), UVM_LOW)
  endfunction
endclass
