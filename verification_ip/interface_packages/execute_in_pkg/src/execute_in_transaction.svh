class execute_in_transaction extends uvm_sequence_item;

  execute_in_transfer_t sample;

  `uvm_object_utils(execute_in_transaction)

  function new(string name = "execute_in_transaction");
    super.new(name);
  endfunction

endclass