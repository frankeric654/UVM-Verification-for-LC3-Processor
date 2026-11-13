class mem_access_in_transaction extends uvm_sequence_item;
    `uvm_object_utils(mem_access_in_transaction)

    logic [1:0]  mem_state;
    logic        M_Control;
    logic [15:0] M_Data;
    logic [15:0] M_Addr;
    logic [15:0] Data_dout;

    function new (string name = "mem_access_in_transaction");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf(
            "mem_state: %b, M_Control: %b, M_Data: %h, M_Addr: %h, Data_dout: %h",
            mem_state, M_Control, M_Data, M_Addr, Data_dout
        );
    endfunction
endclass
