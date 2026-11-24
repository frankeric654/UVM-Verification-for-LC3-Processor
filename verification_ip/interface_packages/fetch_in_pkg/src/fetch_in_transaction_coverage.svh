//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class records fetch_in transaction information using
//       a covergroup named fetch_in_transaction_cg.  An instance of this
//       coverage component is instantiated in the uvmf_parameterized_agent
//       if the has_coverage flag is set.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class fetch_in_transaction_coverage  extends uvm_subscriber #(.T(fetch_in_transaction ));

  `uvm_component_utils( fetch_in_transaction_coverage )

  T coverage_trans;
  int unsigned sample_count = 0;

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
  
  // ****************************************************************************
  covergroup fetch_in_transaction_cg;
    // pragma uvmf custom covergroup begin
    // UVMF_CHANGE_ME : Add coverage bins, crosses, exclusions, etc. according to coverage needs.
    option.auto_bin_max=1024;
    option.per_instance=1;
    enable_updatePC: coverpoint coverage_trans.enable_updatePC;
    enable_fetch: coverpoint coverage_trans.enable_fetch;
    br_taken: coverpoint coverage_trans.br_taken;
    taddr: coverpoint coverage_trans.taddr;
    // pragma uvmf custom covergroup end
  endgroup

  covergroup fetch_in_behavior_cg;
    option.per_instance = 1;

    // Target 3.1: PC-update and fetch-enable combinations.
    cp_update: coverpoint coverage_trans.enable_updatePC;
    cp_fetch: coverpoint coverage_trans.enable_fetch;

    cx_update_fetch: cross cp_update, cp_fetch;

    // Target 3.2: sequential update and branch redirect.
    cp_update_kind: coverpoint coverage_trans.br_taken
      iff (coverage_trans.enable_updatePC) {
        bins sequential = {0};
        bins redirect = {1};
    }

    // Target address is meaningful only during a redirect.
    cp_target: coverpoint coverage_trans.taddr
      iff (coverage_trans.enable_updatePC &&
           coverage_trans.br_taken) {
        bins zero = {16'h0000};
        bins below_reset = {[16'h0001:16'h2fff]};
        bins reset_vector = {16'h3000};
        bins above_reset = {[16'h3001:16'hfffe]};
        bins maximum = {16'hffff};
    }
  endgroup

  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new(string name="", uvm_component parent=null);
    super.new(name,parent);
    fetch_in_transaction_cg=new;
    fetch_in_behavior_cg=new;
  endfunction

  // ****************************************************************************
  // FUNCTION : build_phase()
  // This function is the standard UVM build_phase.
  //
  function void build_phase(uvm_phase phase);
    fetch_in_transaction_cg.set_inst_name($sformatf("fetch_in_transaction_cg_%s",get_full_name()));
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
    fetch_in_transaction_cg.sample();

    fetch_in_behavior_cg.sample();

    sample_count++;
  endfunction


  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("FETCH_TARGET_COV",
      $sformatf("fetch_in: functional coverage=%0.2f%%",
        fetch_in_behavior_cg.get_inst_coverage()),
      UVM_LOW)

    `uvm_info("FETCH_COV",
      $sformatf("fetch_in: samples=%0d coverage=%0.2f%%",
        sample_count,
        fetch_in_transaction_cg.get_inst_coverage()),
      UVM_LOW)
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

