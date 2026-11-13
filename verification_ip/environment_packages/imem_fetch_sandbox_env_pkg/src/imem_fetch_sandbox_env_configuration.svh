//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//                                          
// DESCRIPTION: THis is the configuration for the imem_fetch_sandbox environment.
//  it contains configuration classes for each agent.  It also contains
//  environment level configuration variables.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class imem_fetch_sandbox_env_configuration 
extends uvmf_environment_configuration_base;

  `uvm_object_utils( imem_fetch_sandbox_env_configuration )


//Constraints for the configuration variables:


  covergroup imem_fetch_sandbox_configuration_cg;
    // pragma uvmf custom covergroup begin
    option.auto_bin_max=1024;
    // pragma uvmf custom covergroup end
  endgroup

typedef fetch_env_configuration fetch_env_config_t;
rand fetch_env_config_t fetch_env_config;


    typedef imem_configuration imem_agent_config_t;
    rand imem_agent_config_t imem_agent_config;


    string                fetch_env_interface_names[];
    uvmf_active_passive_t fetch_env_interface_activity[];


  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end

// ****************************************************************************
// FUNCTION : new()
// This function is the standard SystemVerilog constructor.
// This function constructs the configuration object for each agent in the environment.
//
  function new( string name = "" );
    super.new( name );

   fetch_env_config = fetch_env_config_t::type_id::create("fetch_env_config");

    imem_agent_config = imem_agent_config_t::type_id::create("imem_agent_config");

  // pragma uvmf custom new begin
  // pragma uvmf custom new end
  endfunction

// ****************************************************************************
// FUNCTION: post_randomize()
// This function is automatically called after the randomize() function 
// is executed.
//
  function void post_randomize();
    super.post_randomize();
    // pragma uvmf custom post_randomize begin
    // pragma uvmf custom post_randomize end
  endfunction
  
// ****************************************************************************
// FUNCTION: convert2string()
// This function converts all variables in this class to a single string for
// logfile reporting. This function concatenates the convert2string result for
// each agent configuration in this configuration class.
//
  virtual function string convert2string();
    // pragma uvmf custom convert2string begin
    return {
     
     "\n", imem_agent_config.convert2string,
     "\n", fetch_env_config.convert2string

       };
    // pragma uvmf custom convert2string end
  endfunction
// ****************************************************************************
// FUNCTION: initialize();
// This function configures each interface agents configuration class.  The 
// sim level determines the active/passive state of the agent.  The environment_path
// identifies the hierarchy down to and including the instantiation name of the
// environment for this configuration class.  Each instance of the environment 
// has its own configuration class.  The string interface names are used by 
// the agent configurations to identify the virtual interface handle to pull from
// the uvm_config_db.  
//
  function void initialize(uvmf_sim_level_t sim_level, 
                                      string environment_path,
                                      string interface_names[],
                                      uvm_reg_block register_model = null,
                                      uvmf_active_passive_t interface_activity[] = {}
                                     );

    super.initialize(sim_level, environment_path, interface_names, register_model, interface_activity);

  // Interface initialization for sub-environments
    fetch_env_interface_names    = new[2];
    fetch_env_interface_activity = new[2];

    fetch_env_interface_names     = interface_names[0:1];
    fetch_env_interface_activity  = interface_activity[0:1];


  // Interface initialization for local agents
     imem_agent_config.initialize( interface_activity[2], {environment_path,".imem_agent"}, interface_names[2]);
     imem_agent_config.initiator_responder = RESPONDER;
     // imem_agent_config.has_coverage = 1;


     fetch_env_config.initialize( sim_level, {environment_path,".fetch_env"}, fetch_env_interface_names, null,   fetch_env_interface_activity);



  // pragma uvmf custom initialize begin
  // pragma uvmf custom initialize end

  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

