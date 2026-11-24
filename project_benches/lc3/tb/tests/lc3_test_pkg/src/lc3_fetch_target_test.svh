class fetch_address_responder_sequence
    extends imem_directed_responder_sequence;

  `uvm_object_utils(fetch_address_responder_sequence)

  function void append_word(bit [15:0] word,
                            int unsigned padding = 6);
    program_words.push_back(word);
    repeat (padding)
      program_words.push_back(16'h5FE0);
  endfunction

  function new(string name = "fetch_address_responder_sequence");
    super.new(name);
    program_words.delete();

    append_word(16'h5020); // AND R0,R0,#0
    append_word(16'h1223); // ADD R1,R0,#3

    // R1 = 3 << 12 = 0x3000
    repeat (12)
      append_word(16'h1241);

    append_word(16'h943F); // NOT R2,R0 = 0xFFFF
    append_word(16'h1661); // ADD R3,R1,#1 = 0x3001

    append_word(16'hC000, 8); // JMP R0 -> 0x0000
    append_word(16'hC040, 8); // JMP R1 -> 0x3000
    append_word(16'hC080, 8); // JMP R2 -> 0xFFFF
    append_word(16'hC0C0, 8); // JMP R3 -> 0x3001
  endfunction

  virtual protected function bit next_target_word(
      output bit closes_pass);
    bit result;

    result = super.next_target_word(closes_pass);

    if (!result)
      `uvm_info("FETCH_DIRECTED_DONE",
        $sformatf("Delivered=%0d Expected=%0d",
          targets_delivered, expected_target_count()),
        UVM_LOW)

    return result;
  endfunction
endclass

class lc3_fetch_target_test extends lc3_smoke_test;

  `uvm_component_utils(lc3_fetch_target_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    imem_responder_sequence::type_id::set_type_override(
      fetch_address_responder_sequence::get_type());

    super.build_phase(phase);
  endfunction
endclass
