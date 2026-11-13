class mem_access_in_coverage extends uvm_subscriber #(mem_access_in_transaction);
    `uvm_component_utils(mem_access_in_coverage)

    mem_access_in_transaction coverage_trans;

    covergroup cg_mem_access_in;
        option.per_instance = 1;
        state_cp : coverpoint coverage_trans.mem_state {
            bins load_indirect = {2'd0};
            bins load_direct   = {2'd1};
            bins store         = {2'd2};
            bins idle          = {2'd3};
        }
        control_cp : coverpoint coverage_trans.M_Control;
    endgroup

    function new(string name = "mem_access_in_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_mem_access_in = new();
    endfunction

    virtual function void write(mem_access_in_transaction t);
        coverage_trans = t;
        cg_mem_access_in.sample();
    endfunction
endclass : mem_access_in_coverage
