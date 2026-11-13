//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class can be used to provide stimulus when an interface
//              has been configured to run in a responder mode. It
//              will never finish by default, always going back to the driver
//              and driver BFM for the next transaction with which to respond.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class imem_responder_sequence 
  extends imem_sequence_base ;

  `uvm_object_utils( imem_responder_sequence )

  // pragma uvmf custom class_item_additional begin
  // Target stimulus is separate from startup / register initialization / drain.
  // The initial request remains a filler until the real RTL startup trace has
  // confirmed the instructor-model behavior. Do not count it as a target.
  bit          no_repeat = 1'b1;
  int unsigned stop_after_passes = 1; // 0 => time-limited stream, not a finite pass
  int unsigned scope_check_samples = 256;
  bit          first_is_filler = 1'b1;
  bit [15:0]   filler = 16'h1020;      // ADD R0,R0,#0; NOT an initializer

  // Each Rn is cleared by AND Rn,Rn,#0, which does not depend on its old value.
  // Six further legal filler instructions let the clears advance through the
  // short pipeline before targets (including JMP to any BaseR) are supplied.
  // This is startup support, independent of the factory-selected target family.
  bit          initialize_registers = 1'b1;
  int unsigned initialization_padding_words = 6;
  int unsigned initialization_chosen = 0;
  int unsigned initialization_delivered = 0;
  int unsigned initialization_padding_chosen = 0;

  int unsigned responses = 0;          // responses selected for observed requests
  int unsigned targets_delivered = 0;  // conservative driver-completion count
  int unsigned fillers_delivered = 0;  // startup, padding and end-of-test filler
  int unsigned passes_chosen = 0;
  int unsigned passes_done = 0;
  bit          targets_done = 0;
  event        pass_done;

  protected bit last_was_filler = 1'b1;
  protected bit last_was_initialization = 1'b0;
  protected bit last_closes_pass = 1'b0;
  protected bit [15:0] allowed[$];
  protected bit [15:0] remaining[$];

  function int unsigned allowed_count();
    return allowed.size();
  endfunction

  // -1 denotes a time-limited random test, not an enumerated target count.
  virtual function int expected_target_count();
    if (no_repeat && stop_after_passes != 0)
      return int'(allowed.size() * stop_after_passes);
    return -1;
  endfunction

  protected function void build_allowed();
    bit [15:0] saved;
    int unsigned outside;
    saved = req.instr;
    allowed.delete();
    for (int unsigned v = 0; v < 65536; v++)
      if (req.in_scope(v[15:0])) allowed.push_back(v[15:0]);
    if (allowed.size() == 0)
      `uvm_fatal("IMEM_SEQ", {"in_scope() of ", req.get_type_name(), " accepts no instruction word"})
    outside = 0;
    repeat (scope_check_samples) begin
      if (!req.randomize())
        `uvm_fatal("IMEM_SEQ", {"randomize() failed for ", req.get_type_name()})
      else if (!req.in_scope(req.instr))
        outside++;
    end
    if (outside != 0)
      `uvm_fatal("IMEM_SEQ", $sformatf("%0d constrained-random words are outside in_scope() of %s", outside, req.get_type_name()))
    req.instr = saved;
    `uvm_info("IMEM_SEQ", $sformatf("%s: %0d target words in scope; passes=%0d", req.get_type_name(), allowed.size(), stop_after_passes), UVM_LOW)
  endfunction

  virtual protected function bit next_target_word(output bit closes_pass);
    bit [15:0] word;
    closes_pass = 1'b0;
    if (!no_repeat) begin
      if (!req.randomize())
        `uvm_fatal("IMEM_SEQ", "randomize() failed")
      return 1'b1;
    end
    if ((stop_after_passes != 0) && (passes_chosen >= stop_after_passes))
      return 1'b0;
    if (allowed.size() == 0) build_allowed();
    if (remaining.size() == 0) begin
      remaining = allowed;
      remaining.shuffle();
    end
    word = remaining.pop_front();
    if (!req.randomize() with { instr == local::word; })
      `uvm_fatal("IMEM_SEQ", $sformatf("constraints of %s reject pooled word 0x%04h", req.get_type_name(), word))
    if (remaining.size() == 0) begin
      passes_chosen++;
      closes_pass = 1'b1;
    end
    return 1'b1;
  endfunction

  protected function void choose_response();
    bit closes;
    bit [2:0] regno;
    last_was_filler = 1'b1;
    last_was_initialization = 1'b0;
    last_closes_pass = 1'b0;
    req.instr = filler;
    if (first_is_filler && responses == 0) begin
      // Startup filler: not a generated target or a register initialization.
    end else if (initialize_registers && initialization_chosen < 8) begin
      regno = initialization_chosen[2:0];
      req.instr = {4'h5, regno, regno, 1'b1, 5'b00000};
      initialization_chosen++;
      last_was_filler = 1'b0;
      last_was_initialization = 1'b1;
    end else if (initialize_registers && initialization_padding_chosen < initialization_padding_words) begin
      initialization_padding_chosen++;
    end else if (!targets_done) begin
      if (next_target_word(closes)) begin
        last_was_filler = 1'b0;
        last_closes_pass = closes;
      end else begin
        targets_done = 1'b1;
      end
    end
    responses++;
  endfunction

  // finish_item returns after the previous word was physically driven AND
  // the BFM has seen a subsequent request. This is conservative, and is not
  // proof of Decode acceptance / retirement. A timeout catches no progress.
  protected function void note_delivery();
    if (responses == 0) return;
    if (last_was_initialization) initialization_delivered++;
    else if (last_was_filler)    fillers_delivered++;
    else                         targets_delivered++;
    if (last_closes_pass) begin
      passes_done++;
      `uvm_info("IMEM_SEQ", $sformatf("target permutation %0d driven: %0d words", passes_done, allowed.size()), UVM_LOW)
      -> pass_done;
    end
  endfunction
  // pragma uvmf custom class_item_additional end

  function new(string name = "imem_responder_sequence");
    super.new(name);
  endfunction

  task body();
    req=imem_transaction::type_id::create("req");
    forever begin
      start_item(req);
      finish_item(req);
      // pragma uvmf custom body begin
      // The finish_item() that just returned carried the word chosen in the
      // previous iteration: the driver has driven it and req.addr now holds the
      // fetch address of the next request. Count the delivery, then choose the
      // word that the next start_item/finish_item hands back for this request.
      note_delivery();
      choose_response();
      `uvm_info("SEQ", $sformatf("fetch %0d: %s%s", responses, req.convert2string(),
                                 last_was_filler ? " [filler]" : ""), UVM_HIGH)
      // pragma uvmf custom body end
    end
  endtask

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

