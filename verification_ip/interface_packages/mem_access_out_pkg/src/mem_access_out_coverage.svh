class mem_access_out_coverage extends uvm_subscriber #(mem_access_out_transaction);
    `uvm_component_utils(mem_access_out_coverage)

    mem_access_out_transaction coverage_trans;

    covergroup cg_mem_access_out;
        option.per_instance = 1;
        read_cp : coverpoint coverage_trans.Data_rd;
    endgroup

    function new(string name = "mem_access_out_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_mem_access_out = new();
    endfunction

    virtual function void write(mem_access_out_transaction t);
        coverage_trans = t;
        cg_mem_access_out.sample();
    endfunction
endclass : mem_access_out_coverage
