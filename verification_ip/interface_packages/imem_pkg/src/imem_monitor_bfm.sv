//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This interface performs the imem signal monitoring.
//      It is accessed by the uvm imem monitor through a virtual
//      interface handle in the imem configuration.  It monitors the
//      signals passed in through the port connection named bus of
//      type imem_if.
//
//     Input signals from the imem_if are assigned to an internal input
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
//                   blocks until an operation on the imem bus is complete.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import imem_pkg_hdl::*;
`include "src/imem_macros.svh"


interface imem_monitor_bfm 
  ( imem_if  bus );
  // The pragma below and additional ones in-lined further down are for running this BFM on Veloce
  // pragma attribute imem_monitor_bfm partition_interface_xif                                  

  // Structure used to pass transaction data from monitor BFM to monitor class in agent.
`imem_MONITOR_STRUCT
  imem_monitor_s imem_monitor_struct;

  // Structure used to pass configuration data from monitor class to monitor BFM.
 `imem_CONFIGURATION_STRUCT
 

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase

  tri clock_i;
  tri reset_i;
  tri [15:0] pc_i;
  tri  instrmem_rd_i;
  tri [15:0] Instr_dout_i;
  tri  complete_instr_i;
  assign clock_i = bus.clock;
  assign reset_i = bus.reset;
  assign pc_i = bus.pc;
  assign instrmem_rd_i = bus.instrmem_rd;
  assign Instr_dout_i = bus.Instr_dout;
  assign complete_instr_i = bus.complete_instr;

  // Proxy handle to UVM monitor
  imem_pkg::imem_monitor  proxy;
  // pragma tbx oneway proxy.notify_transaction                 

  // pragma uvmf custom interface_item_additional begin
  clocking sample_cb @(posedge clock_i);
    default input #1step;
    input reset_i, pc_i, instrmem_rd_i;
    input Instr_dout_i, complete_instr_i;
  endclocking

  // Request seen in the previous cycle that is waiting for its response.
  // Supported protocol: fixed one-cycle response latency (see imem_driver_bfm).
  // A request without a response in the next cycle is reported, never silently
  // dropped or re-attributed.
  bit        req_pending = 1'b0;
  bit [15:0] req_addr    = 16'h0000;

  // Record the request (if any) of the cycle being sampled. Four-state checks
  // happen here, before anything is converted to two-state values:
  // instrmem_rd must be a known 0 or 1 outside reset.
  function void note_request();
    if ($isunknown(sample_cb.instrmem_rd_i))
      proxy.report_protocol($sformatf(
        "instrmem_rd contains X/Z: %b",
        sample_cb.instrmem_rd_i));

    req_pending = (sample_cb.instrmem_rd_i === 1'b1);

    if (req_pending && $isunknown(sample_cb.pc_i))
      proxy.report_protocol("IMEM request PC contains X/Z");

    req_addr = sample_cb.pc_i;
  endfunction
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
      do_monitor( imem_monitor_struct );
                                                                 
 
      proxy.notify_transaction( imem_monitor_struct );
 
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
    function void configure(imem_configuration_s imem_configuration_arg); // pragma tbx xtf  
    initiator_responder = imem_configuration_arg.initiator_responder;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction   


  // ****************************************************************************  
            
  task do_monitor(output imem_monitor_s imem_monitor_struct);
    //
    // Available struct members:
    //     //    imem_monitor_struct.addr
    //     //    imem_monitor_struct.instr
    //     //
    // Reference code;
    //    How to wait for signal value
    //      while (control_signal == 1'b1) @(posedge clock_i);
    //    
    //    How to assign a struct member, named xyz, from a signal.   
    //    All available input signals listed.
    //      imem_monitor_struct.xyz = pc_i;  //    [15:0] 
    //      imem_monitor_struct.xyz = instrmem_rd_i;  //     
    //      imem_monitor_struct.xyz = Instr_dout_i;  //    [15:0] 
    //      imem_monitor_struct.xyz = complete_instr_i;  //     
    // pragma uvmf custom do_monitor begin
    // Match each rising-edge request to the following
    // rising-edge response sample. Capture the next request
    // before returning, including back-to-back transfers.
    // This observes memory responses, not instruction retirement.
    forever begin
      @(sample_cb);
      if (sample_cb.reset_i !== 1'b0) begin
        req_pending = 1'b0;
      end else begin
        if (req_pending) begin
          if (sample_cb.complete_instr_i === 1'b1) begin
            if ($isunknown(sample_cb.Instr_dout_i))
              proxy.report_protocol($sformatf("Instr_dout=%h has X/Z in the response to pc=%h", sample_cb.Instr_dout_i, req_addr));
            imem_monitor_struct.addr  = req_addr;
            imem_monitor_struct.instr = sample_cb.Instr_dout_i;
            proxy.note_observed_response();
            note_request();
            break;
          end
          proxy.report_protocol($sformatf("complete_instr is not valid in the fixed response cycle for pc=%h (complete_instr=%b)",
                                          req_addr, sample_cb.complete_instr_i));
        end
        note_request();
      end
    end
    // pragma uvmf custom do_monitor end
  endtask         
  
 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

