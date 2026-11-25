class lc3_controller_target_sequence extends imem_directed_responder_sequence;
  `uvm_object_utils(lc3_controller_target_sequence)

  bit target_done_reported;

  function new(string name = "lc3_controller_target_sequence");
    bit [15:0] base_words[$];

    super.new(name);
    base_words = program_words;
    program_words.delete();

    for (int pass = 0; pass < 6; pass++) begin
      program_words.push_back(16'h5020); // Clear R0 for pattern reads.
      for (int pattern = 0; pattern < 7; pattern++) begin
        program_words.push_back(16'h6200 | pattern); // LDR R1, R0, #pattern
        program_words.push_back(16'h7208);            // STR R1, R0, #8
      end
      foreach (base_words[i])
        program_words.push_back(base_words[i]);
    end
  endfunction

  virtual protected function bit next_target_word(output bit closes_pass);
    bit result;

    result = super.next_target_word(closes_pass);
    if (!result && !target_done_reported) begin
      target_done_reported = 1;
      `uvm_info("LC3_CONTROLLER_TARGET_DONE",
        $sformatf("Delivered=%0d Expected=%0d",
          targets_delivered, expected_target_count()),
        UVM_LOW)
    end
    return result;
  endfunction
endclass

class lc3_controller_target_test extends lc3_smoke_test;
  `uvm_component_utils(lc3_controller_target_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    imem_responder_sequence::type_id::set_type_override(
      lc3_controller_target_sequence::get_type());
    super.build_phase(phase);
  endfunction
endclass
