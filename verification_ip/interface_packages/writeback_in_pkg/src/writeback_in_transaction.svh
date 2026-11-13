// One observed WB input sample, wrapped in a UVM data object.
class writeback_in_transaction extends uvm_sequence_item;
  writeback_in_transfer_t sample;
  time edge_time_ps; // Absolute clock-edge time in picoseconds.

  `uvm_object_utils_begin(writeback_in_transaction)
    `uvm_field_int(sample, UVM_DEFAULT)
    `uvm_field_int(edge_time_ps, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "writeback_in_transaction");
    super.new(name);
  endfunction
endclass
  