//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//
//----------------------------------------------------------------------
//
// DESCRIPTION: This analysis component contains analysis_exports for receiving
//   data and analysis_ports for sending data.
// 
//   This analysis component has the following analysis_exports that receive the 
//   listed transaction type.
//   
//   fetch_in_agent_ae receives transactions of type  fetch_in_transaction
//
//   This analysis component has the following analysis_ports that can broadcast 
//   the listed transaction type.
//
//  fetch_sb_ap broadcasts transactions of type fetch_out_transaction
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

class fetch_predictor #(
  type CONFIG_T
  )
 extends uvm_component;

  // Factory registration of this class
  `uvm_component_param_utils( fetch_predictor #(
                              CONFIG_T
                              )
)


  // Instantiate a handle to the configuration of the environment in which this component resides
  CONFIG_T configuration;

  
  // Instantiate the analysis exports
  uvm_analysis_imp_fetch_in_agent_ae #(fetch_in_transaction, fetch_predictor #(
                              .CONFIG_T(CONFIG_T)
                              )
) fetch_in_agent_ae;

  
  // Instantiate the analysis ports
  uvm_analysis_port #(fetch_out_transaction) fetch_sb_ap;


  // Transaction variable for predicted values to be sent out fetch_sb_ap
  typedef fetch_out_transaction fetch_sb_ap_output_transaction_t;
  fetch_sb_ap_output_transaction_t fetch_sb_ap_output_transaction;
  // Code for sending output transaction out through fetch_sb_ap
  // fetch_sb_ap.write(fetch_sb_ap_output_transaction);

  // Define transaction handles for debug visibility 
  fetch_in_transaction fetch_in_agent_ae_debug;


  // pragma uvmf custom class_item_additional begin
  // fetch_model() (lc3_prediction_pkg) keeps the Fetch PC in a static variable.
  // Each call is one clock cycle: it returns the PC the register will hold
  // AFTER this cycle's rising edge (pc, npc = pc + 1) together with THIS
  // cycle's instrmem_rd (= enable_fetch). The fetch_out monitor samples pc and
  // npc_out DURING the cycle, so the expected pc/npc_out for cycle k is what the
  // model returned for cycle k-1; cur_pc/cur_npc carry that value. Before the
  // first cycle they hold the model's reset PC, read with a call that does not
  // advance it (enable_updatePC = 0).
  // Call rule: fetch_model is called here and nowhere else, once per cycle.
  bit          model_primed = 1'b0;
  bit [15:0]   cur_pc;
  bit [15:0]   cur_npc;
  int unsigned cycles_predicted = 0;

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("PRED", $sformatf("fetch_model evaluated for %0d cycles", cycles_predicted), UVM_LOW)
  endfunction
  // pragma uvmf custom class_item_additional end

  // FUNCTION: new
  function new(string name, uvm_component parent);
     super.new(name,parent);
  endfunction

  // FUNCTION: build_phase
  virtual function void build_phase (uvm_phase phase);

    fetch_in_agent_ae = new("fetch_in_agent_ae", this);
    fetch_sb_ap =new("fetch_sb_ap", this );
  endfunction

  // FUNCTION: write_fetch_in_agent_ae
  // Transactions received through fetch_in_agent_ae initiate the execution of this function.
  // This function performs prediction of DUT output values based on DUT input, configuration and state
  virtual function void write_fetch_in_agent_ae(fetch_in_transaction t);
    // pragma uvmf custom fetch_in_agent_ae_predictor begin
    bit [15:0] next_pc;
    bit [15:0] next_npc;
    bit        rd_now;
    bit        unused_rd;
    fetch_in_agent_ae_debug = t;
    `uvm_info("PRED", {"            Data: ",t.convert2string()}, UVM_FULL)
    if (!model_primed) begin
      if (fetch_model(1'b0, 1'b0, 1'b0, 16'h0000, cur_npc, cur_pc, unused_rd))
        `uvm_error("PRED", "fetch_model reported a failure while reading the reset PC")
      model_primed = 1'b1;
    end
    if (fetch_model(t.enable_updatePC, t.enable_fetch, t.br_taken, t.taddr, next_npc, next_pc, rd_now))
      `uvm_error("PRED", {"fetch_model reported a failure for ", t.convert2string()})
    fetch_sb_ap_output_transaction = fetch_sb_ap_output_transaction_t::type_id::create("fetch_sb_ap_output_transaction");
    fetch_sb_ap_output_transaction.pc          = cur_pc;
    fetch_sb_ap_output_transaction.npc_out     = cur_npc;
    fetch_sb_ap_output_transaction.instrmem_rd = rd_now;
    cur_pc  = next_pc;
    cur_npc = next_npc;
    cycles_predicted++;
    `uvm_info("PRED", {"expected fetch_out: ", fetch_sb_ap_output_transaction.convert2string()}, UVM_HIGH)
    fetch_sb_ap.write(fetch_sb_ap_output_transaction);
    // pragma uvmf custom fetch_in_agent_ae_predictor end
  endfunction


endclass 

// pragma uvmf custom external begin
// pragma uvmf custom external end

