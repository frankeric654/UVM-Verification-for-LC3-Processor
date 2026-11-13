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
  // Request seen in the previous cycle that is waiting for its response.
  // Supported protocol: fixed one-cycle response latency (see imem_driver_bfm).
  // A request without a response in the next cycle is reported, never silently
  // dropped or re-attributed.
  bit        req_pending = 1'b0;
  bit [15:0] req_addr    = 16'h0000;

  // Record the request (if any) of the cycle being sampled. Four-state checks
  // happen here, before anything is converted to two-state values:
  // instrmem_rd may be 0 or Z when there is no request; X is an error.
  function void note_request();
    if (instrmem_rd_i === 1'bx)
      proxy.report_protocol("instrmem_rd is X");
    req_pending = (instrmem_rd_i === 1'b1);
    if (req_pending && $isunknown(pc_i))
      proxy.report_protocol($sformatf("fetch request with unknown pc=%h", pc_i));
    req_addr = pc_i;
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
      @(posedge clock_i);  
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
    // One transaction per observed valid response window (not proof that
    // Decode latched it or that held data was refreshed for this request):
    //   addr  = pc of the request (cycle k, instrmem_rd == 1)
    //   instr = Instr_dout in the response cycle k+1 (complete_instr == 1)
    // All signals are sampled at the falling edge, after the LC3 and the
    // responder have settled. Back-to-back fetches are tracked: the request of
    // the current cycle is recorded before returning. A held complete=1 does
    // not distinguish stale data; the v3 smoke CSV checker independently
    // checks the actual pin-word stream against the directed stimulus contract.
    forever begin
      @(negedge clock_i);
      if (reset_i !== 1'b0) begin
        req_pending = 1'b0;
      end else begin
        if (req_pending) begin
          if (complete_instr_i === 1'b1) begin
            if ($isunknown(Instr_dout_i))
              proxy.report_protocol($sformatf("Instr_dout=%h has X/Z in the response to pc=%h", Instr_dout_i, req_addr));
            imem_monitor_struct.addr  = req_addr;
            imem_monitor_struct.instr = Instr_dout_i;
            proxy.note_observed_response();
            note_request();
            break;
          end
          proxy.report_protocol($sformatf("complete_instr is not valid in the fixed response cycle for pc=%h (complete_instr=%b)",
                                          req_addr, complete_instr_i));
        end
        note_request();
      end
    end
    // pragma uvmf custom do_monitor end
  endtask         
  
 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

