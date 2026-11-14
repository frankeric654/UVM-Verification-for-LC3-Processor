`uvm_analysis_imp_decl(_control_expected)
`uvm_analysis_imp_decl(_control_actual)

class control_scoreboard extends uvm_component;
    `uvm_component_utils(control_scoreboard)
    uvm_analysis_imp_control_expected #(control_out_transaction, control_scoreboard) expected_export;
    uvm_analysis_imp_control_actual #(control_out_transaction, control_scoreboard) actual_export;
    control_out_transaction expected_by_cycle[longint unsigned];
    control_out_transaction actual_by_cycle[longint unsigned];
    int unsigned expected_count, actual_count, comparison_count, match_count, mismatch_count;

    function new(string name = "control_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);
    endfunction

    // Either monitor may publish first. Match by cycle, never by scheduling order.
    virtual function void write_control_expected(control_out_transaction t);
        control_out_transaction copy;
        if (expected_by_cycle.exists(t.cycle))
            `uvm_fatal("CONTROL_DUPLICATE", "Duplicate expected cycle")
        $cast(copy, t.clone());
        expected_by_cycle[t.cycle] = copy;
        expected_count++;
        compare_cycle(t.cycle);
    endfunction

    virtual function void write_control_actual(control_out_transaction t);
        control_out_transaction copy;
        if (actual_by_cycle.exists(t.cycle))
            `uvm_fatal("CONTROL_DUPLICATE", "Duplicate actual cycle")
        $cast(copy, t.clone());
        actual_by_cycle[t.cycle] = copy;
        actual_count++;
        compare_cycle(t.cycle);
    endfunction

    protected function void compare_cycle(longint unsigned cycle);
        if (!expected_by_cycle.exists(cycle) || !actual_by_cycle.exists(cycle)) return;
        comparison_count++;
        if (actual_by_cycle[cycle].compare(expected_by_cycle[cycle])) match_count++;
        else begin
            mismatch_count++;
            `uvm_error("CONTROL_MISMATCH", $sformatf("expected: %s\nactual:   %s",
                expected_by_cycle[cycle].convert2string(), actual_by_cycle[cycle].convert2string()))
        end
        expected_by_cycle.delete(cycle);
        actual_by_cycle.delete(cycle);
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (comparison_count == 0)
            `uvm_error("CONTROL_EMPTY", "No controller cycles were checked")
        if (expected_by_cycle.num() || actual_by_cycle.num() ||
            expected_count != actual_count || comparison_count != expected_count)
            `uvm_error("CONTROL_PENDING", $sformatf(
                "expected=%0d actual=%0d compared=%0d pending_expected=%0d pending_actual=%0d",
                expected_count, actual_count, comparison_count,
                expected_by_cycle.num(), actual_by_cycle.num()))
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("CONTROL_SCOREBOARD", $sformatf(
            "expected=%0d actual=%0d compared=%0d matched=%0d mismatched=%0d pending=%0d",
            expected_count, actual_count, comparison_count, match_count, mismatch_count,
            expected_by_cycle.num()+actual_by_cycle.num()), UVM_LOW)
    endfunction
endclass
