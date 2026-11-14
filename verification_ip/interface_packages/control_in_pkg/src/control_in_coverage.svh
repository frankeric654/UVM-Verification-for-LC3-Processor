class control_in_coverage extends uvm_subscriber #(control_in_transaction);
    `uvm_component_utils(control_in_coverage)
    int unsigned sampled_cycles;
    covergroup input_coverage with function sample(control_in_transaction t,
        bit use_sr1, bit use_sr2, bit writes_dr, bit load_producer);
        option.per_instance = 1;
        cp_reset: coverpoint t.reset;
        cp_complete_instr: coverpoint t.complete_instr iff (!t.reset);
        cp_complete_data: coverpoint t.complete_data iff (!t.reset);
        cp_opcode: coverpoint t.Instr_dout[15:12] iff (!t.reset && t.complete_instr) {
            bins supported[] = {0,1,2,3,5,6,7,9,10,11,12,14};
        }
        cp_exec_opcode: coverpoint t.IR_Exec[15:12] iff (!t.reset) {
            bins supported[] = {0,1,2,3,5,6,7,9,10,11,12,14};
        }
        cp_immediate: coverpoint t.IR[5] iff (!t.reset && t.IR[15:12] inside {1,5});
        cp_sr1_dependency: coverpoint (t.IR[8:6] == t.IR_Exec[11:9])
            iff (!t.reset && use_sr1 && writes_dr);
        cp_sr2_dependency: coverpoint
            ((t.IR[15:12] inside {3,7,11} ? t.IR[11:9] : t.IR[2:0]) == t.IR_Exec[11:9])
            iff (!t.reset && use_sr2 && writes_dr);
        cp_load_producer: coverpoint load_producer iff (!t.reset && writes_dr);
        sr1_source: cross cp_sr1_dependency, cp_load_producer;
        sr2_source: cross cp_sr2_dependency, cp_load_producer;
        cp_branch_mask: coverpoint t.NZP iff (!t.reset && t.IR_Exec[15:12] == 0) {
            bins masks[] = {[0:7]};
        }
        cp_psr: coverpoint t.psr iff (!t.reset && t.IR_Exec[15:12] == 0) {
            bins n = {4}; bins z = {2}; bins p = {1};
        }
        branch_conditions: cross cp_branch_mask, cp_psr;
    endgroup

    function new(string name = "control_in_coverage", uvm_component parent = null);
        super.new(name, parent);
        input_coverage = new;
        input_coverage.set_inst_name({get_full_name(), ".input_coverage"});
    endfunction

    virtual function void write(control_in_transaction t);
        bit use_sr1, use_sr2, writes_dr, load_producer;
        use_sr1 = t.IR[15:12] inside {1,5,6,7,9,12};
        use_sr2 = t.IR[15:12] inside {3,7,11} ||
                  (t.IR[15:12] inside {1,5} && !t.IR[5]);
        writes_dr = t.IR_Exec[15:12] inside {1,2,5,6,9,10,14};
        load_producer = t.IR_Exec[15:12] inside {2,6,10};
        sampled_cycles++;
        input_coverage.sample(t, use_sr1, use_sr2, writes_dr, load_producer);
    endfunction
endclass
