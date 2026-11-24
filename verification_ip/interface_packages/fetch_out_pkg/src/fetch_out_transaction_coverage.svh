//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class records fetch_out transaction information using
//       a covergroup named fetch_out_transaction_cg.  An instance of this
//       coverage component is instantiated in the uvmf_parameterized_agent
//       if the has_coverage flag is set.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class fetch_out_transaction_coverage  extends uvm_subscriber #(.T(fetch_out_transaction ));

  `uvm_component_utils( fetch_out_transaction_coverage )

  T coverage_trans;
  int unsigned sample_count = 0;
  bit previous_valid = 0;
  bit [15:0] previous_pc;
  bit [15:0] pc_delta;


  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
  
  // ****************************************************************************
  covergroup fetch_out_transaction_cg;
    // pragma uvmf custom covergroup begin
    // UVMF_CHANGE_ME : Add coverage bins, crosses, exclusions, etc. according to coverage needs.
    option.auto_bin_max=1024;
    option.per_instance=1;
    pc: coverpoint coverage_trans.pc;
    npc_out: coverpoint coverage_trans.npc_out;
    instrmem_rd: coverpoint coverage_trans.instrmem_rd;
    // pragma uvmf custom covergroup end
  endgroup

  covergroup fetch_out_behavior_cg;
    option.per_instance = 1;

    // Target 3.3: observed PC movement between samples.
    cp_pc_motion: coverpoint pc_delta iff (previous_valid) {
        bins hold = {16'h0000};
        bins increment = {16'h0001};
        bins other = {[16'h0002:16'hffff]};
    }

    // Target 3.4: instruction-memory request activity.
    cp_read: coverpoint coverage_trans.instrmem_rd {
        bins inactive = {0};
        bins active = {1};
    }

    cp_read_transition:
      coverpoint coverage_trans.instrmem_rd {
        bins start_read = (0 => 1);
        bins stop_read = (1 => 0);
        bins continue_read = (1 => 1);
        bins continue_idle = (0 => 0);
    }
  endgroup

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    fetch_out_transaction_cg=new;
    fetch_out_behavior_cg=new;
  endfunction

  // ****************************************************************************
  // FUNCTION : build_phase()
  // This function is the standard UVM build_phase.
  //
  function void build_phase(uvm_phase phase);
    fetch_out_transaction_cg.set_inst_name($sformatf("fetch_out_transaction_cg_%s",get_full_name()));
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
    fetch_out_transaction_cg.sample();

    pc_delta = coverage_trans.pc - previous_pc;
    fetch_out_behavior_cg.sample();
    previous_pc = coverage_trans.pc;
    previous_valid = 1;

    sample_count++;
  endfunction


  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("FETCH_TARGET_COV",
      $sformatf("fetch_out: functional coverage=%0.2f%%",
        fetch_out_behavior_cg.get_inst_coverage()),
      UVM_LOW)

    `uvm_info("FETCH_COV",
      $sformatf("fetch_out: samples=%0d coverage=%0.2f%%",
        sample_count,
        fetch_out_transaction_cg.get_inst_coverage()),
      UVM_LOW)
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

