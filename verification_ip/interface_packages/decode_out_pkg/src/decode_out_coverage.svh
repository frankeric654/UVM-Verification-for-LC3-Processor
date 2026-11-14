class decode_out_coverage extends uvm_subscriber #(decode_out_transaction);

    `uvm_component_utils(decode_out_coverage)
    decode_out_transaction coverage_trans;

    function new(string name = "decode_out_coverage", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase
    
    virtual function void write(decode_out_transaction t);
        `uvm_info("COV", "Received transaction", UVM_HIGH);
        coverage_trans = t;
    endfunction : write

endclass : decode_out_coverage