class decode_out_transaction extends uvm_sequence_item;

    `uvm_object_utils(decode_out_transaction)

    logic [15:0]    IR; // equal to the input Instr_dout (instruction)
    logic [15:0]    npc_out; // reflects the value of npc_in
    logic [5:0]     E_control; // signal that controls the execute unit
    logic [1:0]     W_control; // selects the writeback destination
    logic           Mem_control; // controls memory-related operations

    function new (string name = "decode_out_transaction");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("IR: %h, npc_out: %h, E_control: %b, W_control: %b, Mem_control: %b", 
            IR, npc_out, E_control, W_control, Mem_control
        );
    endfunction

    // implement compare function
    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        decode_out_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("COMPARE", "Object not of type decode_out_transaction")
        end

        if (IR !== rhs_.IR) begin
            `uvm_error("COMPARE", $sformatf("IR mismatch: %h != %h", IR, rhs_.IR))
            return 0;
        end

        if (npc_out !== rhs_.npc_out) begin
            `uvm_error("COMPARE", $sformatf("npc_out mismatch: %h != %h", npc_out, rhs_.npc_out))
            return 0;
        end

        if (E_control !== rhs_.E_control) begin
            `uvm_error("COMPARE", $sformatf("E_control mismatch: %b != %b", E_control, rhs_.E_control))
            return 0;
        end

        if (W_control !== rhs_.W_control) begin
            `uvm_error("COMPARE", $sformatf("W_control mismatch: %b != %b", W_control, rhs_.W_control))
            return 0;
        end

        if (Mem_control !== rhs_.Mem_control) begin
            `uvm_error("COMPARE", $sformatf("Mem_control mismatch: %b != %b", Mem_control, rhs_.Mem_control))
            return 0;
        end

        return 1; // All fields match
    endfunction

    virtual function void do_copy(uvm_object rhs);
        decode_out_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("COPY", "Object not of type decode_out_transaction")
        end

        super.do_copy(rhs); // Call the base class copy method

        IR = rhs_.IR;
        npc_out = rhs_.npc_out;
        E_control = rhs_.E_control;
        W_control = rhs_.W_control;
        Mem_control = rhs_.Mem_control;
    endfunction
endclass
