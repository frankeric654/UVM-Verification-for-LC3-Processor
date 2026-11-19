
class execute_configuration extends uvm_object;

  `uvm_object_utils(execute_configuration)

  // Enable or disable scoreboard checking.
  bit enable_scoreboard = 1'b1;

  // Enable or disable predictor operation.
  bit enable_predictor = 1'b1;

  // Enable transaction-level logging.
  bit enable_transaction_logging = 1'b0;

  function new(string name = "execute_configuration");
    super.new(name);
  endfunction

endclass
/*尚未細讀*/
