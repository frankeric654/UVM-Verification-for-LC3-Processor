class mem_access_out_random_sequence extends uvm_sequence #(mem_access_out_transaction);
    `uvm_object_utils(mem_access_out_random_sequence)

    function new(string name = "mem_access_out_random_sequence");
        super.new(name);
    endfunction
endclass
