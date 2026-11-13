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

class imem_fetch_sandbox_environment  extends uvmf_environment_base #(
    .CONFIG_T( imem_fetch_sandbox_env_configuration 
  ));
  `uvm_component_utils( imem_fetch_sandbox_environment )

  typedef fetch_environment fetch_env_t;
  fetch_env_t fetch_env;
   




  typedef imem_agent  imem_agent_agent_t;
  imem_agent_agent_t imem_agent;







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
    fetch_env = fetch_env_t::type_id::create("fetch_env",this);
    fetch_env.set_config(configuration.fetch_env_config);
    imem_agent = imem_agent_agent_t::type_id::create("imem_agent",this);
    imem_agent.set_config(configuration.imem_agent_config);
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
    // pragma uvmf custom reg_model_connect_phase begin
    // pragma uvmf custom reg_model_connect_phase end
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

