
class execute_out_transaction extends uvm_sequence_item;

  execute_out_transfer_t sample;

  `uvm_object_utils(execute_out_transaction)

  function new(string name = "execute_out_transaction");
    super.new(name);
  endfunction

endclass
