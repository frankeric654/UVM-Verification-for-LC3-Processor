//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// Description: This file contains the top level and utility sequences
//     used by test_top. It can be extended to create derivative top
//     level sequences.
//
//----------------------------------------------------------------------
//
//----------------------------------------------------------------------
//

class imem_fetch_sandbox_bench_sequence_base extends uvmf_sequence_base #(uvm_sequence_item);

  `uvm_object_utils( imem_fetch_sandbox_bench_sequence_base );

  // pragma uvmf custom sequences begin
  // UVMF_CHANGE_ME : Instantiate, construct, and start sequences as needed to create stimulus scenarios.
  // Instantiate sequences here
  typedef imem_responder_sequence  imem_agent_responder_seq_t;
  imem_agent_responder_seq_t imem_agent_responder_seq;
  // pragma uvmf custom sequences end

  // Sequencer handles for each active interface in the environment
  typedef imem_transaction  imem_agent_transaction_t;
  uvm_sequencer #(imem_agent_transaction_t)  imem_agent_sequencer; 


  // Top level environment configuration handle
  typedef imem_fetch_sandbox_env_configuration  imem_fetch_sandbox_env_configuration_t;
  imem_fetch_sandbox_env_configuration_t top_configuration;

  // Configuration handles to access interface BFM's
  fetch_in_configuration  fetch_env_fetch_in_agent_config;
  fetch_out_configuration  fetch_env_fetch_out_agent_config;
  imem_configuration  imem_agent_config;

  // pragma uvmf custom class_item_additional begin
  // Run control.
  //  * Permutation responder (no_repeat=1): the main phase ends when the last
  //    word of the requested passes has been conservatively driver-confirmed;
  //    max_clocks is only a safety cap and fails the test if it is reached.
  //  * Otherwise the main phase lasts run_clocks cycles.
  //  * Then the responder sends only the filler (no new target stimulus) for
  //    drain_clocks cycles as a bounded settling allowance, and ends at
  //    a rising edge. Both Fetch monitors sample every cycle, so expected and
  //    actual stay paired; the UVMF scoreboard's end-of-test checks report
  //    anything left over. This allowance must be checked on the real RTL;
  //    it is not proof of retirement with arbitrary data-memory latency.
  int unsigned run_clocks   = 20000;
  int unsigned max_clocks   = 500000;
  int unsigned drain_clocks = 50;
  // pragma uvmf custom class_item_additional end

  // ****************************************************************************
  function new( string name = "" );
    super.new( name );
    // Retrieve the configuration handles from the uvm_config_db

    // Retrieve top level configuration handle
    if ( !uvm_config_db#(imem_fetch_sandbox_env_configuration_t)::get(null,UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG",top_configuration) ) begin
      `uvm_info("CFG", "*** FATAL *** uvm_config_db::get can not find TOP_ENV_CONFIG.  Are you using an older UVMF release than what was used to generate this bench?",UVM_NONE);
      `uvm_fatal("CFG", "uvm_config_db#(imem_fetch_sandbox_env_configuration_t)::get cannot find resource TOP_ENV_CONFIG");
    end

    // Retrieve config handles for all agents
    if( !uvm_config_db #( fetch_in_configuration )::get( null , UVMF_CONFIGURATIONS , fetch_env_fetch_in_agent_BFM , fetch_env_fetch_in_agent_config ) ) 
      `uvm_fatal("CFG" , "uvm_config_db #( fetch_in_configuration )::get cannot find resource fetch_env_fetch_in_agent_BFM" )
    if( !uvm_config_db #( fetch_out_configuration )::get( null , UVMF_CONFIGURATIONS , fetch_env_fetch_out_agent_BFM , fetch_env_fetch_out_agent_config ) ) 
      `uvm_fatal("CFG" , "uvm_config_db #( fetch_out_configuration )::get cannot find resource fetch_env_fetch_out_agent_BFM" )
    if( !uvm_config_db #( imem_configuration )::get( null , UVMF_CONFIGURATIONS , imem_agent_BFM , imem_agent_config ) ) 
      `uvm_fatal("CFG" , "uvm_config_db #( imem_configuration )::get cannot find resource imem_agent_BFM" )

    // Assign the sequencer handles from the handles within agent configurations
    imem_agent_sequencer = imem_agent_config.get_sequencer();



    // pragma uvmf custom new begin
    // pragma uvmf custom new end

  endfunction

  // ****************************************************************************
  virtual task body();
    // pragma uvmf custom body begin
    int expected_targets;
    imem_agent_responder_seq = imem_agent_responder_seq_t::type_id::create("imem_agent_responder_seq");
    fork
      imem_agent_responder_seq.start(imem_agent_sequencer);
    join_none
    fork
      fetch_env_fetch_in_agent_config.wait_for_reset();
      fetch_env_fetch_out_agent_config.wait_for_reset();
      imem_agent_config.wait_for_reset();
    join
    if (imem_agent_responder_seq.no_repeat && imem_agent_responder_seq.stop_after_passes != 0) begin
      // Isolate the watchdog fork so disabling it cannot kill the responder.
      fork
        begin : wait_for_target_passes
          fork
            wait (imem_agent_responder_seq.passes_done >= imem_agent_responder_seq.stop_after_passes);
            imem_agent_config.wait_for_num_clocks(max_clocks);
          join_any
          disable fork;
        end
      join
      if (imem_agent_responder_seq.passes_done < imem_agent_responder_seq.stop_after_passes)
        `uvm_error("IMEM_PROGRESS", $sformatf("timeout: only %0d target passes completed", imem_agent_responder_seq.passes_done))
    end else begin
      imem_agent_config.wait_for_num_clocks(run_clocks);
    end

    // Keep servicing memory with legal filler; no new target permutation.
    imem_agent_responder_seq.targets_done = 1'b1;
    imem_agent_config.wait_for_num_clocks(drain_clocks);
    expected_targets = imem_agent_responder_seq.expected_target_count();
    if (imem_agent_responder_seq.initialize_registers && imem_agent_responder_seq.initialization_delivered != 8)
      `uvm_error("IMEM_PROGRESS", $sformatf("only %0d/8 initialization words were driven", imem_agent_responder_seq.initialization_delivered))
    if (imem_agent_responder_seq.targets_delivered == 0)
      `uvm_error("IMEM_PROGRESS", "no target instruction was driven")
    if (expected_targets >= 0 && imem_agent_responder_seq.targets_delivered != expected_targets)
      `uvm_error("IMEM_PROGRESS", $sformatf("target count %0d, expected %0d", imem_agent_responder_seq.targets_delivered, expected_targets))
    `uvm_info("P3_SEQUENCE_RESULT", $sformatf("targets=%0d expected=%0d initialization=%0d filler=%0d passes=%0d",
                  imem_agent_responder_seq.targets_delivered, expected_targets,
                  imem_agent_responder_seq.initialization_delivered,
                  imem_agent_responder_seq.fillers_delivered,
                  imem_agent_responder_seq.passes_done), UVM_LOW)
    // pragma uvmf custom body end
  endtask

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

