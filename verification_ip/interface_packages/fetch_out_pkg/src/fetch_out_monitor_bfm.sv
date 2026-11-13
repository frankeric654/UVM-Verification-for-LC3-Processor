//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This interface performs the fetch_out signal monitoring.
//      It is accessed by the uvm fetch_out monitor through a virtual
//      interface handle in the fetch_out configuration.  It monitors the
//      signals passed in through the port connection named bus of
//      type fetch_out_if.
//
//     Input signals from the fetch_out_if are assigned to an internal input
//     signal with a _i suffix.  The _i signal should be used for sampling.
//
//     The input signal connections are as follows:
//       bus.signal -> signal_i 
//
//      Interface functions and tasks used by UVM components:
//             monitor(inout TRANS_T txn);
//                   This task receives the transaction, txn, from the
//                   UVM monitor and then populates variables in txn
//                   from values observed on bus activity.  This task
//                   blocks until an operation on the fetch_out bus is complete.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import fetch_out_pkg_hdl::*;
`include "src/fetch_out_macros.svh"


interface fetch_out_monitor_bfm 
  ( fetch_out_if  bus );
  // The pragma below and additional ones in-lined further down are for running this BFM on Veloce
  // pragma attribute fetch_out_monitor_bfm partition_interface_xif                                  

  // Structure used to pass transaction data from monitor BFM to monitor class in agent.
`fetch_out_MONITOR_STRUCT
  fetch_out_monitor_s fetch_out_monitor_struct;

  // Structure used to pass configuration data from monitor class to monitor BFM.
 `fetch_out_CONFIGURATION_STRUCT
 

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase

  tri clock_i;
  tri reset_i;
  tri [15:0] pc_i;
  tri [15:0] npc_out_i;
  tri  instrmem_rd_i;
  assign clock_i = bus.clock;
  assign reset_i = bus.reset;
  assign pc_i = bus.pc;
  assign npc_out_i = bus.npc_out;
  assign instrmem_rd_i = bus.instrmem_rd;

  // Proxy handle to UVM monitor
  fetch_out_pkg::fetch_out_monitor  proxy;
  // pragma tbx oneway proxy.notify_transaction                 

  // pragma uvmf custom interface_item_additional begin
  // pragma uvmf custom interface_item_additional end
  
  //******************************************************************                         
  task wait_for_reset();// pragma tbx xtf  
    @(posedge clock_i) ;                                                                    
    do_wait_for_reset();                                                                   
  endtask                                                                                   

  // ****************************************************************************              
  task do_wait_for_reset(); 
  // pragma uvmf custom reset_condition begin
    wait ( reset_i == 0 ) ;                                                              
    @(posedge clock_i) ;                                                                    
  // pragma uvmf custom reset_condition end                                                                
  endtask    

  //******************************************************************                         
 
  task wait_for_num_clocks(input int unsigned count); // pragma tbx xtf 
    @(posedge clock_i);  
                                                                   
    repeat (count-1) @(posedge clock_i);                                                    
  endtask      

  //******************************************************************                         
  event go;                                                                                 
  function void start_monitoring();// pragma tbx xtf    
    -> go;
  endfunction                                                                               
  
  // ****************************************************************************              
  initial begin                                                                             
    @go;                                                                                   
    forever begin                                                                        
      @(posedge clock_i);  
      do_monitor( fetch_out_monitor_struct );
                                                                 
 
      proxy.notify_transaction( fetch_out_monitor_struct );
 
    end                                                                                    
  end                                                                                       

  //******************************************************************
  // The configure() function is used to pass agent configuration
  // variables to the monitor BFM.  It is called by the monitor within
  // the agent at the beginning of the simulation.  It may be called 
  // during the simulation if agent configuration variables are updated
  // and the monitor BFM needs to be aware of the new configuration 
  // variables.
  //
    function void configure(fetch_out_configuration_s fetch_out_configuration_arg); // pragma tbx xtf  
    initiator_responder = fetch_out_configuration_arg.initiator_responder;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction   


  // ****************************************************************************  
            
  task do_monitor(output fetch_out_monitor_s fetch_out_monitor_struct);
    //
    // Available struct members:
    //     //    fetch_out_monitor_struct.pc
    //     //    fetch_out_monitor_struct.npc_out
    //     //    fetch_out_monitor_struct.instrmem_rd
    //     //
    // Reference code;
    //    How to wait for signal value
    //      while (control_signal == 1'b1) @(posedge clock_i);
    //    
    //    How to assign a struct member, named xyz, from a signal.   
    //    All available input signals listed.
    //      fetch_out_monitor_struct.xyz = pc_i;  //    [15:0] 
    //      fetch_out_monitor_struct.xyz = npc_out_i;  //    [15:0] 
    //      fetch_out_monitor_struct.xyz = instrmem_rd_i;  //     
    // pragma uvmf custom do_monitor begin
    // One transaction per clock cycle outside reset, sampled at the falling
    // edge (mid-cycle), i.e. the PC register value during that cycle and the
    // instrmem_rd of that cycle. Same cycles as fetch_in_monitor_bfm, so the
    // scoreboard sees exactly one actual per expected.
    do @(negedge clock_i);
    while (reset_i !== 1'b0);
    // Four-state checks before the two-state conversion. pc and npc_out must
    // always be known after reset. instrmem_rd: 1 = read; 0 or Z = no read
    // (Z is allowed when Fetch is not reading); X is an error. fetch_model
    // returns 0 for "no read", so 0 and Z are both mapped to 0 explicitly.
    if ($isunknown(pc_i) || $isunknown(npc_out_i))
      proxy.report_xz($sformatf("pc=%h npc_out=%h", pc_i, npc_out_i));
    if (instrmem_rd_i === 1'bx)
      proxy.report_xz("instrmem_rd is X");
    fetch_out_monitor_struct.pc          = pc_i;
    fetch_out_monitor_struct.npc_out     = npc_out_i;
    fetch_out_monitor_struct.instrmem_rd = (instrmem_rd_i === 1'b1);
    // pragma uvmf custom do_monitor end
  endtask         
  
 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

