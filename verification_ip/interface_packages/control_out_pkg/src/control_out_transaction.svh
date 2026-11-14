class control_out_transaction extends uvm_sequence_item;
    longint unsigned cycle;
    time sample_time;
    logic reset;
    logic enable_updatePC;
    logic enable_fetch;
    logic enable_decode;
    logic enable_execute;
    logic enable_writeback;
    logic bypass_alu_1;
    logic bypass_alu_2;
    logic bypass_mem_1;
    logic bypass_mem_2;
    logic [1:0] mem_state;
    logic br_taken;

    `uvm_object_utils_begin(control_out_transaction)
        `uvm_field_int(cycle, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(sample_time, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(reset, UVM_DEFAULT)
        `uvm_field_int(enable_updatePC, UVM_DEFAULT)
        `uvm_field_int(enable_fetch, UVM_DEFAULT)
        `uvm_field_int(enable_decode, UVM_DEFAULT)
        `uvm_field_int(enable_execute, UVM_DEFAULT)
        `uvm_field_int(enable_writeback, UVM_DEFAULT)
        `uvm_field_int(bypass_alu_1, UVM_DEFAULT)
        `uvm_field_int(bypass_alu_2, UVM_DEFAULT)
        `uvm_field_int(bypass_mem_1, UVM_DEFAULT)
        `uvm_field_int(bypass_mem_2, UVM_DEFAULT)
        `uvm_field_int(mem_state, UVM_DEFAULT)
        `uvm_field_int(br_taken, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "control_out_transaction");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("cycle=%0d reset=%b enable_updatePC=%b enable_fetch=%b enable_decode=%b enable_execute=%b enable_writeback=%b bypass_alu_1=%b bypass_alu_2=%b bypass_mem_1=%b bypass_mem_2=%b mem_state=%b br_taken=%b",
                         cycle, reset, enable_updatePC, enable_fetch, enable_decode, enable_execute, enable_writeback, bypass_alu_1, bypass_alu_2, bypass_mem_1, bypass_mem_2, mem_state, br_taken);
    endfunction
endclass
