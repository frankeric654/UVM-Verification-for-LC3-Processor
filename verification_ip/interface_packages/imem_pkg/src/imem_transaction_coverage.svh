//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class records imem transaction information using
//       a covergroup named imem_transaction_cg.  An instance of this
//       coverage component is instantiated in the uvmf_parameterized_agent
//       if the has_coverage flag is set.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class imem_transaction_coverage  extends uvm_subscriber #(.T(imem_transaction ));

  `uvm_component_utils( imem_transaction_coverage )

  T coverage_trans;

  // pragma uvmf custom class_item_additional begin
  // Guard helper used by the covergroup.
  function bit op_is(imem_opcode_e op);
    return (coverage_trans.instr[15:12] == op);
  endfunction

  // Field combinations per instruction family (cross bins of the model below).
  localparam int unsigned ALU_COMBOS  = 9280;    // ADD 2560 + AND 2560 + NOT 64 + LEA 4096
  localparam int unsigned MEM_COMBOS  = 24576;   // LD, LDI, LDR, ST, STI, STR: 4096 each
  localparam int unsigned CTRL_COMBOS = 4104;    // BR 4096 + JMP 8

  // Bins hit in one cross/coverpoint = its instance coverage x its bin count.
  protected function int unsigned bins_hit(real percent, int unsigned nbins);
    return $rtoi(percent * nbins / 100.0 + 0.5);
  endfunction

  function int unsigned alu_hits();
    return bins_hit(imem_transaction_cg.add_reg_x.get_inst_coverage(), 512)
         + bins_hit(imem_transaction_cg.add_imm_x.get_inst_coverage(), 2048)
         + bins_hit(imem_transaction_cg.and_reg_x.get_inst_coverage(), 512)
         + bins_hit(imem_transaction_cg.and_imm_x.get_inst_coverage(), 2048)
         + bins_hit(imem_transaction_cg.not_x.get_inst_coverage(),     64)
         + bins_hit(imem_transaction_cg.lea_x.get_inst_coverage(),     4096);
  endfunction

  function int unsigned mem_hits();
    return bins_hit(imem_transaction_cg.ld_x.get_inst_coverage(),  4096)
         + bins_hit(imem_transaction_cg.ldi_x.get_inst_coverage(), 4096)
         + bins_hit(imem_transaction_cg.ldr_x.get_inst_coverage(), 4096)
         + bins_hit(imem_transaction_cg.st_x.get_inst_coverage(),  4096)
         + bins_hit(imem_transaction_cg.sti_x.get_inst_coverage(), 4096)
         + bins_hit(imem_transaction_cg.str_x.get_inst_coverage(), 4096);
  endfunction

  function int unsigned ctrl_hits();
    return bins_hit(imem_transaction_cg.br_x.get_inst_coverage(),     4096)
         + bins_hit(imem_transaction_cg.jmp_base.get_inst_coverage(), 8);
  endfunction

  function int unsigned combinations_hit();
    return alu_hits() + mem_hits() + ctrl_hits();
  endfunction

  // Test-level goal. A test sets which families must be complete:
  //   uvm_config_db #(bit [2:0])::set(this, "*", "imem_cov_required_families", mask);
  //   bit 0 = ALU, bit 1 = MEM, bit 2 = CONTROL; default 0 = report only.
  // A required family with any missing combination fails the test here. This is
  // our own model's goal; the instructor's bound-in model is graded separately.
  function void check_phase(uvm_phase phase);
    bit [2:0] required;
    super.check_phase(phase);
    required = 3'b000;
    void'(uvm_config_db #(bit [2:0])::get(this, "", "imem_cov_required_families", required));
    if (required[0] && (alu_hits() != ALU_COMBOS))
      `uvm_error("IMEM_COV", $sformatf("ALU family: %0d of %0d combinations hit", alu_hits(), ALU_COMBOS))
    if (required[1] && (mem_hits() != MEM_COMBOS))
      `uvm_error("IMEM_COV", $sformatf("MEM family: %0d of %0d combinations hit", mem_hits(), MEM_COMBOS))
    if (required[2] && (ctrl_hits() != CTRL_COMBOS))
      `uvm_error("IMEM_COV", $sformatf("CONTROL family: %0d of %0d combinations hit", ctrl_hits(), CTRL_COMBOS))
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("IMEM_COV", $sformatf("instruction field combinations hit: %0d of 37960 (ALU %0d/%0d, MEM %0d/%0d, CONTROL %0d/%0d); covergroup %0.2f%%",
                                    combinations_hit(), alu_hits(), ALU_COMBOS, mem_hits(), MEM_COMBOS,
                                    ctrl_hits(), CTRL_COMBOS, imem_transaction_cg.get_inst_coverage()), UVM_LOW)
  endfunction
  // pragma uvmf custom class_item_additional end
  
  // ****************************************************************************
  covergroup imem_transaction_cg;
    // pragma uvmf custom covergroup begin
    // Instruction coverage model (DRAFT, strictest reading of the P3 rubric:
    // "every valid instruction including the register fields and immediate
    // values"). Every legal field combination of the 12 implemented LC3
    // instructions is a cross bin:
    //   ADD 2560 + AND 2560 + NOT 64 + BR 4096 + JMP 8 + LD/LDI/LEA 3x4096
    //   + ST/STI 2x4096 + LDR/STR 2x4096 = 37,960 combinations.
    // Field-level coverpoints explain holes; the crosses are the closure goal.
    // Sampled once per completed fetch (see imem_monitor_bfm).
    option.per_instance = 1;
    option.auto_bin_max = 512;   // one automatic bin per value for fields up to 9 bits

    opcode : coverpoint coverage_trans.instr[15:12] {
      bins op_br  = {IMEM_BR};  bins op_add = {IMEM_ADD}; bins op_ld  = {IMEM_LD};
      bins op_st  = {IMEM_ST};  bins op_and = {IMEM_AND}; bins op_ldr = {IMEM_LDR};
      bins op_str = {IMEM_STR}; bins op_not = {IMEM_NOT}; bins op_ldi = {IMEM_LDI};
      bins op_sti = {IMEM_STI}; bins op_jmp = {IMEM_JMP}; bins op_lea = {IMEM_LEA};
      illegal_bins op_unsupported = {IMEM_JSR, IMEM_RTI, IMEM_TRAP, IMEM_RESERVED};
    }

    // Bits with a fixed value in every legal encoding.
    fix_addand : coverpoint coverage_trans.instr[4:3]
                 iff ((op_is(IMEM_ADD) || op_is(IMEM_AND)) && !coverage_trans.instr[5]) {
      bins zero = {2'b00};
      illegal_bins nonzero = {[2'b01:2'b11]};
    }
    fix_not : coverpoint coverage_trans.instr[5:0] iff (op_is(IMEM_NOT)) {
      bins ones = {6'h3F};
      illegal_bins other = {[6'h00:6'h3E]};
    }
    fix_jmp : coverpoint {coverage_trans.instr[11:9], coverage_trans.instr[5:0]} iff (op_is(IMEM_JMP)) {
      bins zero = {9'h000};
      illegal_bins other = {[9'h001:9'h1FF]};
    }

    // ADD DR, SR1, SR2 | ADD DR, SR1, #imm5
    add_dr    : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_ADD));
    add_sr1   : coverpoint coverage_trans.instr[8:6]  iff (op_is(IMEM_ADD));
    add_mode  : coverpoint coverage_trans.instr[5]    iff (op_is(IMEM_ADD));
    add_sr2   : coverpoint coverage_trans.instr[2:0]  iff (op_is(IMEM_ADD) && !coverage_trans.instr[5]);
    add_imm5  : coverpoint coverage_trans.instr[4:0]  iff (op_is(IMEM_ADD) &&  coverage_trans.instr[5]);
    add_reg_x : cross add_dr, add_sr1, add_sr2  iff (op_is(IMEM_ADD) && !coverage_trans.instr[5]);
    add_imm_x : cross add_dr, add_sr1, add_imm5 iff (op_is(IMEM_ADD) &&  coverage_trans.instr[5]);

    // AND DR, SR1, SR2 | AND DR, SR1, #imm5
    and_dr    : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_AND));
    and_sr1   : coverpoint coverage_trans.instr[8:6]  iff (op_is(IMEM_AND));
    and_mode  : coverpoint coverage_trans.instr[5]    iff (op_is(IMEM_AND));
    and_sr2   : coverpoint coverage_trans.instr[2:0]  iff (op_is(IMEM_AND) && !coverage_trans.instr[5]);
    and_imm5  : coverpoint coverage_trans.instr[4:0]  iff (op_is(IMEM_AND) &&  coverage_trans.instr[5]);
    and_reg_x : cross and_dr, and_sr1, and_sr2  iff (op_is(IMEM_AND) && !coverage_trans.instr[5]);
    and_imm_x : cross and_dr, and_sr1, and_imm5 iff (op_is(IMEM_AND) &&  coverage_trans.instr[5]);

    // NOT DR, SR
    not_dr : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_NOT));
    not_sr : coverpoint coverage_trans.instr[8:6]  iff (op_is(IMEM_NOT));
    not_x  : cross not_dr, not_sr iff (op_is(IMEM_NOT));

    // BR[n][z][p] PCoffset9 (nzp = 000 included: legal encoding, never taken)
    br_nzp  : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_BR));
    br_off9 : coverpoint coverage_trans.instr[8:0]  iff (op_is(IMEM_BR));
    br_x    : cross br_nzp, br_off9 iff (op_is(IMEM_BR));

    // JMP BaseR
    jmp_base : coverpoint coverage_trans.instr[8:6] iff (op_is(IMEM_JMP));

    // LD / LDI / LEA DR, PCoffset9
    ld_dr    : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_LD));
    ld_off9  : coverpoint coverage_trans.instr[8:0]  iff (op_is(IMEM_LD));
    ld_x     : cross ld_dr, ld_off9 iff (op_is(IMEM_LD));
    ldi_dr   : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_LDI));
    ldi_off9 : coverpoint coverage_trans.instr[8:0]  iff (op_is(IMEM_LDI));
    ldi_x    : cross ldi_dr, ldi_off9 iff (op_is(IMEM_LDI));
    lea_dr   : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_LEA));
    lea_off9 : coverpoint coverage_trans.instr[8:0]  iff (op_is(IMEM_LEA));
    lea_x    : cross lea_dr, lea_off9 iff (op_is(IMEM_LEA));

    // ST / STI SR, PCoffset9
    st_sr    : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_ST));
    st_off9  : coverpoint coverage_trans.instr[8:0]  iff (op_is(IMEM_ST));
    st_x     : cross st_sr, st_off9 iff (op_is(IMEM_ST));
    sti_sr   : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_STI));
    sti_off9 : coverpoint coverage_trans.instr[8:0]  iff (op_is(IMEM_STI));
    sti_x    : cross sti_sr, sti_off9 iff (op_is(IMEM_STI));

    // LDR DR, BaseR, offset6 | STR SR, BaseR, offset6
    ldr_dr   : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_LDR));
    ldr_base : coverpoint coverage_trans.instr[8:6]  iff (op_is(IMEM_LDR));
    ldr_off6 : coverpoint coverage_trans.instr[5:0]  iff (op_is(IMEM_LDR));
    ldr_x    : cross ldr_dr, ldr_base, ldr_off6 iff (op_is(IMEM_LDR));
    str_sr   : coverpoint coverage_trans.instr[11:9] iff (op_is(IMEM_STR));
    str_base : coverpoint coverage_trans.instr[8:6]  iff (op_is(IMEM_STR));
    str_off6 : coverpoint coverage_trans.instr[5:0]  iff (op_is(IMEM_STR));
    str_x    : cross str_sr, str_base, str_off6 iff (op_is(IMEM_STR));
    // pragma uvmf custom covergroup end
  endgroup

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    imem_transaction_cg=new;
  endfunction

  // ****************************************************************************
  // FUNCTION : build_phase()
  // This function is the standard UVM build_phase.
  //
  function void build_phase(uvm_phase phase);
    imem_transaction_cg.set_inst_name($sformatf("imem_transaction_cg_%s",get_full_name()));
  endfunction

  // ****************************************************************************
  // FUNCTION: write (T t)
  // This function is automatically executed when a transaction arrives on the
  // analysis_export.  It copies values from the variables in the transaction 
  // to local variables used to collect functional coverage.  
  //
  virtual function void write (T t);
    `uvm_info("COV","Received transaction",UVM_HIGH);
    coverage_trans = t;
    imem_transaction_cg.sample();
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

