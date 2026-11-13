//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
// Description: This top level UVM test is the base class for all
//     future tests created for this project.
//
//     This test class contains:
//          Configuration:  The top level configuration for the project.
//          Environment:    The top level environment for the project.
//          Top_level_sequence:  The top level sequence for the project.
//                                        
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

typedef imem_fetch_sandbox_env_configuration imem_fetch_sandbox_env_configuration_t;
typedef imem_fetch_sandbox_environment imem_fetch_sandbox_environment_t;

class test_top extends uvmf_test_base #(.CONFIG_T(imem_fetch_sandbox_env_configuration_t), 
                                        .ENV_T(imem_fetch_sandbox_environment_t), 
                                        .TOP_LEVEL_SEQ_T(imem_fetch_sandbox_bench_sequence_base));

  `uvm_component_utils( test_top );



  string interface_names[] = {
    fetch_env_fetch_in_agent_BFM /* fetch_env_fetch_in_agent     [0] */ , 
    fetch_env_fetch_out_agent_BFM /* fetch_env_fetch_out_agent     [1] */ , 
    imem_agent_BFM /* imem_agent     [2] */ 
};

uvmf_active_passive_t interface_activities[] = { 
    PASSIVE /* fetch_env_fetch_in_agent     [0] */ , 
    PASSIVE /* fetch_env_fetch_out_agent     [1] */ , 
    ACTIVE /* imem_agent     [2] */   };

  // pragma uvmf custom class_item_additional begin
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (environment.imem_agent.monitor.responses_observed == 0)
      `uvm_error("P3_ACTIVITY", "IMem monitor observed no responses")
    if (environment.fetch_env.fetch_sb.match_count == 0)
      `uvm_error("P3_ACTIVITY", "Fetch scoreboard performed no matching comparisons")
    if (!environment.fetch_env.fetch_sb.scoreboard_enabled ||
        !environment.fetch_env.fetch_sb.enable_expected_port ||
        !environment.fetch_env.fetch_sb.enable_actual_port ||
         environment.fetch_env.fetch_sb.disable_entry_compare)
      `uvm_error("P3_ACTIVITY", "Fetch comparison path has been disabled")
    if (environment.fetch_env.fetch_sb.mismatch_count != 0 ||
        environment.fetch_env.fetch_sb.nothing_to_compare_against_count != 0)
      `uvm_error("P3_ACTIVITY", "Fetch scoreboard has mismatches or unmatched actual transactions")
    `uvm_info("P3_CHECKS_COMPLETE", $sformatf("imem_observed=%0d fetch_matches=%0d fetch_mismatches=%0d unmatched_actual=%0d protocol_errors=%0d",
        environment.imem_agent.monitor.responses_observed,
        environment.fetch_env.fetch_sb.match_count,
        environment.fetch_env.fetch_sb.mismatch_count,
        environment.fetch_env.fetch_sb.nothing_to_compare_against_count,
        environment.imem_agent.monitor.protocol_errors), UVM_LOW)
  endfunction
  // pragma uvmf custom class_item_additional end

  // ****************************************************************************
  // FUNCTION: new()
  // This is the standard systemVerilog constructor.  All components are 
  // constructed in the build_phase to allow factory overriding.
  //
  function new( string name = "", uvm_component parent = null );
     super.new( name ,parent );
  endfunction



  // ****************************************************************************
  // FUNCTION: build_phase()
  // The construction of the configuration and environment classes is done in
  // the build_phase of uvmf_test_base.  Once the configuraton and environment
  // classes are built then the initialize call is made to perform the
  // following: 
  //     Monitor and driver BFM virtual interface handle passing into agents
  //     Set the active/passive state for each agent
  // Once this build_phase completes, the build_phase of the environment is
  // executed which builds the agents.
  //
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // pragma uvmf custom configuration_settings_post_randomize begin
    // test_top sends every legal instruction word once, so all three
    // instruction families must be complete in the imem coverage model.
    // Derived tests set their own goal after calling super.build_phase().
    uvm_config_db #(bit [2:0])::set(this, "*", "imem_cov_required_families", 3'b111);
    // pragma uvmf custom configuration_settings_post_randomize end
    configuration.initialize(NA, "uvm_test_top.environment", interface_names, null, interface_activities);
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

