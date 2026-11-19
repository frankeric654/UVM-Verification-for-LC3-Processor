
`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class execute_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(execute_scoreboard)

  // Receive expected transactions from the predictor.
  uvm_analysis_imp_expected #(
    execute_out_transaction,
    execute_scoreboard
  ) expected_imp;

  // Receive actual transactions from the output monitor.
  uvm_analysis_imp_actual #(
    execute_out_transaction,
    execute_scoreboard
  ) actual_imp;

  // In-order storage for expected transactions.
  uvm_tlm_analysis_fifo #(execute_out_transaction)
    expected_fifo;

  // In-order storage for actual transactions.
  uvm_tlm_analysis_fifo #(execute_out_transaction)
    actual_fifo;

  // Scoreboard statistics.
  int unsigned expected_count;
  int unsigned actual_count;
  int unsigned match_count;
  int unsigned mismatch_count;
  int unsigned no_expected_count;

  // Track the initial sample before synchronous reset takes effect.
  int unsigned skipped_count;
  bit first_sample_pending;

  function new(string name = "execute_scoreboard",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    expected_imp = new("expected_imp", this);
    actual_imp   = new("actual_imp", this);
    expected_fifo = new("expected_fifo", this);
    actual_fifo   = new("actual_fifo", this);

    expected_count = 0;
    actual_count = 0;
    match_count = 0;
    mismatch_count = 0;
    no_expected_count = 0;

    skipped_count = 0;
    first_sample_pending = 1;
  endfunction

  // Called when the predictor sends an expected transaction.
  virtual function void write_expected(
    execute_out_transaction tx
  );
    execute_out_transaction tx_copy;

    tx_copy = execute_out_transaction::type_id::create(
      "expected_copy"
    );
    tx_copy.sample = tx.sample;

    expected_count++;

    // Nonblocking insertion into the analysis FIFO.
    if (!expected_fifo.try_put(tx_copy)) begin
      `uvm_error("EXE_SB", "Failed to store expected transaction")
    end

    compare_pairs();
  endfunction

  // Called when the output monitor sends an actual transaction.
  virtual function void write_actual(
    execute_out_transaction tx
  );
    execute_out_transaction tx_copy;

    tx_copy = execute_out_transaction::type_id::create(
      "actual_copy"
    );
    tx_copy.sample = tx.sample;

    actual_count++;

    if (!actual_fifo.try_put(tx_copy)) begin
      `uvm_error("EXE_SB", "Failed to store actual transaction")
    end

    compare_pairs();
  endfunction

  // Compare transactions only when both FIFOs contain data.
  virtual function void compare_pairs();

    execute_out_transaction expected_tx;
    execute_out_transaction actual_tx;

    while ((expected_fifo.used() > 0) &&
           (actual_fifo.used() > 0)) begin

      if (!expected_fifo.try_get(expected_tx)) begin
        `uvm_error("EXE_SB",
          "Failed to retrieve expected transaction")
        return;
      end

      if (!actual_fifo.try_get(actual_tx)) begin
        `uvm_error("EXE_SB",
          "Failed to retrieve actual transaction")
        return;
      end

      // Skip only the first pair, sampled before synchronous reset
      // has initialized the DUT's registered outputs.
      if (first_sample_pending) begin

        first_sample_pending = 0;
        skipped_count++;

        `uvm_info("EXE_SB",
          "Skipping first transaction before reset initialization",
          UVM_LOW)

        continue;
      end

      // Compare all Execute output signals.
      if (expected_tx.sample === actual_tx.sample) begin

        match_count++;

        `uvm_info("EXE_SB",
          $sformatf("MATCH: transaction %0d",
                    match_count + mismatch_count + skipped_count),
          UVM_MEDIUM)

      end
      else begin

        mismatch_count++;

        `uvm_error("EXE_SB",
          $sformatf(
            "MISMATCH: transaction %0d\nExpected: %p\nActual: %p",
            match_count + mismatch_count + skipped_count,
            expected_tx.sample,
            actual_tx.sample
          ))

      end
    end
  endfunction

  // Check for unconsumed expected transactions.
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (expected_fifo.used() != 0) begin
      `uvm_error("EXE_SB",
        $sformatf(
          "%0d expected transactions remain in FIFO",
          expected_fifo.used()
        ))
    end

    if (actual_fifo.used() != 0) begin

      no_expected_count += actual_fifo.used();

      `uvm_error("EXE_SB",
        $sformatf(
          "%0d actual transactions remain without expected transactions",
          actual_fifo.used()
        ))
    end

    if (expected_count == 0) begin
      `uvm_error("EXE_SB",
        "No expected transactions were received")
    end
  endfunction

  // Report scoreboard statistics.
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("EXE_SB",
      $sformatf(
        "Expected=%0d Actual=%0d Match=%0d Mismatch=%0d Skipped=%0d NoExpected=%0d Remaining=%0d",
        expected_count,
        actual_count,
        match_count,
        mismatch_count,
        skipped_count,
        no_expected_count,
        expected_fifo.used() + actual_fifo.used()
      ),
      UVM_LOW)
  endfunction

endclass
/*尚未細讀*/
