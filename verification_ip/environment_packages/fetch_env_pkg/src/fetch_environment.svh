//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//                                          
// DESCRIPTION: This environment contains all agents, predictors and
// scoreboards required for the block level design.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

class fetch_environment  extends uvmf_environment_base #(
    .CONFIG_T( fetch_env_configuration 
  ));
  `uvm_component_utils( fetch_environment )





  typedef fetch_in_agent  fetch_in_agent_agent_t;
  fetch_in_agent_agent_t fetch_in_agent;

  typedef fetch_out_agent  fetch_out_agent_agent_t;
  fetch_out_agent_agent_t fetch_out_agent;




  typedef fetch_predictor #(
                .CONFIG_T(CONFIG_T)
                )
 fetch_pred_t;
  fetch_pred_t fetch_pred;

  typedef uvmf_in_order_race_scoreboard #(.T(fetch_out_transaction))  fetch_sb_t;
  fetch_sb_t fetch_sb;


  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end
 
// ****************************************************************************
// FUNCTION : new()
// This function is the standard SystemVerilog constructor.
//
  function new( string name = "", uvm_component parent = null );
    super.new( name, parent );
  endfunction

// ****************************************************************************
// FUNCTION: build_phase()
// This function builds all components within this environment.
//
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    fetch_in_agent = fetch_in_agent_agent_t::type_id::create("fetch_in_agent",this);
    fetch_in_agent.set_config(configuration.fetch_in_agent_config);
    fetch_out_agent = fetch_out_agent_agent_t::type_id::create("fetch_out_agent",this);
    fetch_out_agent.set_config(configuration.fetch_out_agent_config);
    fetch_pred = fetch_pred_t::type_id::create("fetch_pred",this);
    fetch_pred.configuration = configuration;
    fetch_sb = fetch_sb_t::type_id::create("fetch_sb",this);
    // pragma uvmf custom build_phase begin
    // pragma uvmf custom build_phase end
  endfunction

// ****************************************************************************
// FUNCTION: connect_phase()
// This function makes all connections within this environment.  Connections
// typically inclue agent to predictor, predictor to scoreboard and scoreboard
// to agent.
//
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    fetch_in_agent.monitored_ap.connect(fetch_pred.fetch_in_agent_ae);
    fetch_pred.fetch_sb_ap.connect(fetch_sb.expected_analysis_export);
    fetch_out_agent.monitored_ap.connect(fetch_sb.actual_analysis_export);
    // pragma uvmf custom reg_model_connect_phase begin
    // pragma uvmf custom reg_model_connect_phase end
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

