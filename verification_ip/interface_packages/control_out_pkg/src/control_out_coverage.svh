class control_out_coverage extends uvm_subscriber #(control_out_transaction);
    `uvm_component_utils(control_out_coverage)
    int unsigned sampled_cycles;
    covergroup output_coverage with function sample(control_out_transaction t);
        option.per_instance = 1;
        cp_reset: coverpoint t.reset;
        cp_enables: coverpoint {t.enable_updatePC, t.enable_fetch, t.enable_decode,
                                t.enable_execute, t.enable_writeback} iff (!t.reset) {
            bins stalled = {0};
            bins full_pipeline = {31};
            bins other[] = {[1:30]};
        }
        cp_mem_state: coverpoint t.mem_state iff (!t.reset) {
            bins read = {0}; bins indirect = {1}; bins write = {2}; bins idle = {3};
            bins start_read = (3 => 0);
            bins start_write = (3 => 2);
            bins start_indirect = (3 => 1);
            bins idle_wait = (3 => 3);
            bins read_wait = (0 => 0);
            bins indirect_wait = (1 => 1);
            bins write_wait = (2 => 2);
            bins pointer_to_read = (1 => 0);
            bins pointer_to_write = (1 => 2);
            bins read_done = (0 => 3);
            bins write_done = (2 => 3);
            illegal_bins illegal_transitions =
                (0 => 1), (0 => 2), (1 => 3), (2 => 0), (2 => 1);
        }
        cp_alu_1: coverpoint t.bypass_alu_1 iff (!t.reset);
        cp_alu_2: coverpoint t.bypass_alu_2 iff (!t.reset);
        cp_mem_1: coverpoint t.bypass_mem_1 iff (!t.reset);
        cp_mem_2: coverpoint t.bypass_mem_2 iff (!t.reset);
        cp_branch: coverpoint t.br_taken iff (!t.reset);
        cp_update_pc: coverpoint t.enable_updatePC iff (!t.reset);
        branch_pc: cross cp_branch, cp_update_pc;
    endgroup

    function new(string name = "control_out_coverage", uvm_component parent = null);
        super.new(name, parent);
        output_coverage = new;
        output_coverage.set_inst_name({get_full_name(), ".output_coverage"});
    endfunction

    virtual function void write(control_out_transaction t);
        sampled_cycles++;
        output_coverage.sample(t);
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("CONTROL_OUT_COV",
            $sformatf("Controller output functional coverage=%0.2f%%",
                      output_coverage.get_inst_coverage()),
            UVM_LOW)
    endfunction
endclass
