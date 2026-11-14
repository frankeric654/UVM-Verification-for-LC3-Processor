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
            bins pointer_to_read = (1 => 0);
            bins pointer_to_write = (1 => 2);
            bins read_done = (0 => 3);
            bins write_done = (2 => 3);
            bins waiting[] = (0 => 0), (1 => 1), (2 => 2);
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
endclass
