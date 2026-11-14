class mem_access_out_transaction extends uvm_sequence_item;
    `uvm_object_utils(mem_access_out_transaction)

    logic [15:0] Data_addr;
    logic [15:0] Data_din;
    logic        Data_rd;
    logic [15:0] memout;

    function new(string name = "mem_access_out_transaction");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf(
            "Data_addr: %h, Data_din: %h, Data_rd: %b, memout: %h",
            Data_addr, Data_din, Data_rd, memout
        );
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        mem_access_out_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            return 0;
        end
        return Data_addr === rhs_.Data_addr &&
               Data_din  === rhs_.Data_din &&
               Data_rd   === rhs_.Data_rd &&
               memout    === rhs_.memout;
    endfunction

    virtual function void do_copy(uvm_object rhs);
        mem_access_out_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("COPY", "Object not of type mem_access_out_transaction")
        end
        super.do_copy(rhs);
        Data_addr = rhs_.Data_addr;
        Data_din = rhs_.Data_din;
        Data_rd = rhs_.Data_rd;
        memout = rhs_.memout;
    endfunction
endclass
