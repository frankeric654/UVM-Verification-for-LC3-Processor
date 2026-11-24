  // Independent Fetch pin-level contract audit.
  // Experimental instrumentation; does not drive the DUT.
  clocking fetch_audit_cb @(posedge clock);
    default input #1step;
    input rst = reset;
    input upc = fetch_in_bus.enable_updatePC;
    input fe = fetch_in_bus.enable_fetch;
    input br = fetch_in_bus.br_taken;
    input target = fetch_in_bus.taddr;
    input pc = fetch_out_bus.pc;
    input npc = fetch_out_bus.npc_out;
    input rd = imem_bus.instrmem_rd;
    input ci = imem_bus.complete_instr;
    input word = imem_bus.Instr_dout;
  endclocking

  bit fa_valid = 0;

  logic fa_prev_reset;
  logic fa_prev_upc, fa_prev_br, fa_prev_rd;
  logic [15:0] fa_prev_pc, fa_prev_target;
  logic [15:0] fa_expected_pc;

  int unsigned fa_reset = 0;
  int unsigned fa_release = 0;
  int unsigned fa_hold = 0;
  int unsigned fa_increment = 0;
  int unsigned fa_redirect = 0;
  int unsigned fa_wrap = 0;
  int unsigned fa_npc = 0;
  int unsigned fa_requests = 0;
  int unsigned fa_responses = 0;
  int unsigned fa_wait_resume = 0;
  int unsigned fa_complete_low = 0;
  int unsigned fa_rd_zero = 0;
  int unsigned fa_rd_z = 0;

  always @(fetch_audit_cb) begin

    if ($isunknown(fetch_audit_cb.rst))
      $error("FETCH_AUDIT: Unknown reset");

    if (fa_valid) begin

      if (fa_prev_reset === 1'b1) begin
        if (fetch_audit_cb.pc !== 16'h3000)
          $error("FETCH_AUDIT: Incorrect reset PC");

        fa_reset++;

        if (fetch_audit_cb.rst === 1'b0)
          fa_release++;

      end else if (fetch_audit_cb.rst === 1'b0) begin

        if (fa_prev_upc === 1'b0) begin
          fa_expected_pc = fa_prev_pc;
          fa_hold++;

        end else if (fa_prev_upc === 1'b1) begin

          if (fa_prev_br === 1'b1) begin
            fa_expected_pc = fa_prev_target;
            fa_redirect++;

          end else begin
            fa_expected_pc = fa_prev_pc + 16'd1;
            fa_increment++;

            if (fa_prev_pc === 16'hffff)
              fa_wrap++;
          end

        end else begin
          fa_expected_pc = 16'hxxxx;
          $error("FETCH_AUDIT: Unknown updatePC enable");
        end

        if (fetch_audit_cb.pc !== fa_expected_pc)
          $error("FETCH_AUDIT: PC transition mismatch");

        if (fa_prev_upc === 1'b0 &&
            fetch_audit_cb.upc === 1'b1)
          fa_wait_resume++;

        // Existing IMEM contract: one-cycle response.
        if (fa_prev_rd === 1'b1) begin
          if (fetch_audit_cb.ci !== 1'b1 ||
              $isunknown(fetch_audit_cb.word))
            $error("FETCH_AUDIT: Invalid IMEM response");

          fa_responses++;
        end
      end
    end

    if (fetch_audit_cb.rst === 1'b0) begin

      if ($isunknown({
          fetch_audit_cb.pc,
          fetch_audit_cb.npc,
          fetch_audit_cb.upc,
          fetch_audit_cb.fe,
          fetch_audit_cb.br
      }))
        $error("FETCH_AUDIT: Unknown Fetch signal");

      if (fetch_audit_cb.npc !==
          (fetch_audit_cb.pc + 16'd1))
        $error("FETCH_AUDIT: NPC mismatch");

      fa_npc++;

      if (fetch_audit_cb.fe === 1'b1) begin
        if (fetch_audit_cb.rd !== 1'b1)
          $error("FETCH_AUDIT: Missing IMEM read");
      end else begin
        if (!(fetch_audit_cb.rd === 1'b0 ||
              fetch_audit_cb.rd === 1'bz))
          $error("FETCH_AUDIT: Invalid inactive read pin");
      end

      if (fetch_audit_cb.rd === 1'b1)
        fa_requests++;

      if (fetch_audit_cb.rd === 1'b0)
        fa_rd_zero++;

      if (fetch_audit_cb.rd === 1'bz)
        fa_rd_z++;

      if (fetch_audit_cb.ci === 1'b0)
        fa_complete_low++;

    end

    fa_prev_reset = fetch_audit_cb.rst;
    fa_prev_upc = fetch_audit_cb.upc;
    fa_prev_br = fetch_audit_cb.br;
    fa_prev_rd = fetch_audit_cb.rd;
    fa_prev_pc = fetch_audit_cb.pc;
    fa_prev_target = fetch_audit_cb.target;
    fa_valid = 1;
  end

  final begin
    $display("FETCH_AUDIT reset=%0d release=%0d hold=%0d increment=%0d redirect=%0d wrap=%0d npc=%0d requests=%0d responses=%0d resume=%0d complete_low=%0d rd_zero=%0d rd_z=%0d",
      fa_reset, fa_release, fa_hold, fa_increment,
      fa_redirect, fa_wrap, fa_npc, fa_requests,
      fa_responses, fa_wait_resume, fa_complete_low,
      fa_rd_zero, fa_rd_z);
  end
