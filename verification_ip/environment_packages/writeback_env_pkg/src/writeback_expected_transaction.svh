// Masks prevent two-state model outputs from hiding uninitialized/X data.
class writeback_expected_transaction extends writeback_out_transaction;
  bit check_d1, check_d2, check_psr;
  `uvm_object_utils_begin(writeback_expected_transaction)
    `uvm_field_int(check_d1, UVM_DEFAULT)
    `uvm_field_int(check_d2, UVM_DEFAULT)
    `uvm_field_int(check_psr, UVM_DEFAULT)
  `uvm_object_utils_end
  function new(string name = "writeback_expected_transaction");
    super.new(name);
  endfunction
endclass
