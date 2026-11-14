class control_in_transaction extends uvm_sequence_item;
    longint unsigned cycle;
    time sample_time;
    logic reset;
    logic complete_data;
    logic complete_instr;
    logic [15:0] IR;
    logic [15:0] IR_Exec;
    logic [15:0] Instr_dout;
    logic [2:0] NZP;
    logic [2:0] psr;

    `uvm_object_utils_begin(control_in_transaction)
        `uvm_field_int(cycle, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(sample_time, UVM_DEFAULT | UVM_NOCOMPARE)
        `uvm_field_int(reset, UVM_DEFAULT)
        `uvm_field_int(complete_data, UVM_DEFAULT)
        `uvm_field_int(complete_instr, UVM_DEFAULT)
        `uvm_field_int(IR, UVM_DEFAULT)
        `uvm_field_int(IR_Exec, UVM_DEFAULT)
        `uvm_field_int(Instr_dout, UVM_DEFAULT)
        `uvm_field_int(NZP, UVM_DEFAULT)
        `uvm_field_int(psr, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "control_in_transaction");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("cycle=%0d reset=%b complete_data=%b complete_instr=%b IR=%h IR_Exec=%h Instr_dout=%h NZP=%b psr=%b",
                         cycle, reset, complete_data, complete_instr, IR, IR_Exec, Instr_dout, NZP, psr);
    endfunction
endclass
