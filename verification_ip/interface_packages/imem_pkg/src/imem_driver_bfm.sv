//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: 
//    This interface performs the imem signal driving.  It is
//     accessed by the uvm imem driver through a virtual interface
//     handle in the imem configuration.  It drives the singals passed
//     in through the port connection named bus of type imem_if.
//
//     Input signals from the imem_if are assigned to an internal input
//     signal with a _i suffix.  The _i signal should be used for sampling.
//
//     The input signal connections are as follows:
//       bus.signal -> signal_i 
//
//     This bfm drives signals with a _o suffix.  These signals
//     are driven onto signals within imem_if based on INITIATOR/RESPONDER and/or
//     ARBITRATION/GRANT status.  
//
//     The output signal connections are as follows:
//        signal_o -> bus.signal
//
//                                                                                           
//      Interface functions and tasks used by UVM components:
//
//             configure:
//                   This function gets configuration attributes from the
//                   UVM driver to set any required BFM configuration
//                   variables such as 'initiator_responder'.                                       
//                                                                                           
//             initiate_and_get_response:
//                   This task is used to perform signaling activity for initiating
//                   a protocol transfer.  The task initiates the transfer, using
//                   input data from the initiator struct.  Then the task captures
//                   response data, placing the data into the response struct.
//                   The response struct is returned to the driver class.
//
//             respond_and_wait_for_next_transfer:
//                   This task is used to complete a current transfer as a responder
//                   and then wait for the initiator to start the next transfer.
//                   The task uses data in the responder struct to drive protocol
//                   signals to complete the transfer.  The task then waits for 
//                   the next transfer.  Once the next transfer begins, data from
//                   the initiator is placed into the initiator struct and sent
//                   to the responder sequence for processing to determine 
//                   what data to respond with.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import imem_pkg_hdl::*;
`include "src/imem_macros.svh"

interface imem_driver_bfm 
  (imem_if bus);
  // The following pragma and additional ones in-lined further below are for running this BFM on Veloce
  // pragma attribute imem_driver_bfm partition_interface_xif
  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase

  tri clock_i;
  tri reset_i;

  // Signal list (all signals are capable of being inputs and outputs for the sake
  // of supporting both INITIATOR and RESPONDER mode operation. Expectation is that 
  // directionality in the config file was from the point-of-view of the INITIATOR

  // INITIATOR mode input signals
  tri [15:0] Instr_dout_i;
  reg [15:0] Instr_dout_o = 16'h1020;
  tri  complete_instr_i;
  reg  complete_instr_o = 1'b0;

  // INITIATOR mode output signals
  tri [15:0] pc_i;
  reg [15:0] pc_o = 'bz;
  tri  instrmem_rd_i;
  reg  instrmem_rd_o = 'bz;

  // Bi-directional signals
  

  assign clock_i = bus.clock;
  assign reset_i = bus.reset;

  // These are signals marked as 'input' by the config file, but the signals will be
  // driven by this BFM if put into RESPONDER mode (flipping all signal directions around)
  assign Instr_dout_i = bus.Instr_dout;
  assign bus.Instr_dout = (initiator_responder == RESPONDER) ? Instr_dout_o : 'bz;
  assign complete_instr_i = bus.complete_instr;
  assign bus.complete_instr = (initiator_responder == RESPONDER) ? complete_instr_o : 'bz;


  // These are signals marked as 'output' by the config file, but the outputs will
  // not be driven by this BFM unless placed in INITIATOR mode.
  assign bus.pc = (initiator_responder == INITIATOR) ? pc_o : 'bz;
  assign pc_i = bus.pc;
  assign bus.instrmem_rd = (initiator_responder == INITIATOR) ? instrmem_rd_o : 'bz;
  assign instrmem_rd_i = bus.instrmem_rd;

  // Proxy handle to UVM driver
  imem_pkg::imem_driver   proxy;
  // pragma tbx oneway proxy.my_function_name_in_uvm_driver                 

  // ****************************************************************************
  // **************************************************************************** 
  // Macros that define structs located in imem_macros.svh
  // ****************************************************************************
  // Struct for passing configuration data from imem_driver to this BFM
  // ****************************************************************************
  `imem_CONFIGURATION_STRUCT
  // ****************************************************************************
  // Structs for INITIATOR and RESPONDER data flow
  //*******************************************************************
  // Initiator macro used by imem_driver and imem_driver_bfm
  // to communicate initiator driven data to imem_driver_bfm.           
  `imem_INITIATOR_STRUCT
    imem_initiator_s initiator_struct;
  // Responder macro used by imem_driver and imem_driver_bfm
  // to communicate Responder driven data to imem_driver_bfm.
  `imem_RESPONDER_STRUCT
    imem_responder_s responder_struct;

  // ****************************************************************************
// pragma uvmf custom reset_condition_and_response begin
  // Always block used to return signals to reset value upon assertion of reset
  always @( posedge reset_i )
     begin
       // RESPONDER mode output signals
       Instr_dout_o <= 16'h1020;
       complete_instr_o <= 1'b0;
       // INITIATOR mode output signals
       pc_o <= 'bz;
       instrmem_rd_o <= 'bz;
       // Bi-directional signals
 
     end    
// pragma uvmf custom reset_condition_and_response end

  // pragma uvmf custom interface_item_additional begin
  clocking request_cb @(posedge clock_i);
    default input #1step;
    input reset_i, pc_i, instrmem_rd_i, Instr_dout_i;
  endclocking

  realtime request_sample_time;
  bit [15:0] request_addr;

  // pragma uvmf custom interface_item_additional end

  //******************************************************************
  // The configure() function is used to pass agent configuration
  // variables to the driver BFM.  It is called by the driver within
  // the agent at the beginning of the simulation.  It may be called 
  // during the simulation if agent configuration variables are updated
  // and the driver BFM needs to be aware of the new configuration 
  // variables.
  //

  function void configure(imem_configuration_s imem_configuration_arg); // pragma tbx xtf  
    initiator_responder = imem_configuration_arg.initiator_responder;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction                                                                             

// pragma uvmf custom initiate_and_get_response begin
// ****************************************************************************
// UVMF_CHANGE_ME
// This task is used by an initator.  The task first initiates a transfer then
// waits for the responder to complete the transfer.
    task initiate_and_get_response( 
       // This argument passes transaction variables used by an initiator
       // to perform the initial part of a protocol transfer.  The values
       // come from a sequence item created in a sequence.
       input imem_initiator_s imem_initiator_struct, 
       // This argument is used to send data received from the responder
       // back to the sequence item.  The sequence item is returned to the sequence.
       output imem_responder_s imem_responder_struct 
       );// pragma tbx xtf  
       // 
       // Members within the imem_initiator_struct:
       //   bit [15:0] addr ;
       //   bit [15:0] instr ;
       // Members within the imem_responder_struct:
       //   bit [15:0] addr ;
       //   bit [15:0] instr ;
       initiator_struct = imem_initiator_struct;
       //
       // Reference code;
       //    How to wait for signal value
       //      while (control_signal == 1'b1) @(posedge clock_i);
       //    
       //    How to assign a responder struct member, named xyz, from a signal.   
       //    All available input signals listed.
       //      imem_responder_struct.xyz = pc_i;  //    [15:0] 
       //      imem_responder_struct.xyz = instrmem_rd_i;  //     
       //      imem_responder_struct.xyz = Instr_dout_i;  //    [15:0] 
       //      imem_responder_struct.xyz = complete_instr_i;  //     
       //    How to assign a signal, named xyz, from an initiator struct member.   
       //    All available input signals listed.
       //    Notice the _o.  Those are storage variables that allow for procedural assignment.
       //      pc_o <= imem_initiator_struct.xyz;  //    [15:0] 
       //      instrmem_rd_o <= imem_initiator_struct.xyz;  //     
       //      Instr_dout_o <= imem_initiator_struct.xyz;  //    [15:0] 
       //      complete_instr_o <= imem_initiator_struct.xyz;  //     
    // Initiate a transfer using the data received.
    @(posedge clock_i);
    @(posedge clock_i);
    // Wait for the responder to complete the transfer then place the responder data into 
    // imem_responder_struct.
    @(posedge clock_i);
    @(posedge clock_i);
    responder_struct = imem_responder_struct;
  endtask        
// pragma uvmf custom initiate_and_get_response end

// pragma uvmf custom respond_and_wait_for_next_transfer begin
// ****************************************************************************
// LC3 instruction-memory RESPONDER (ECE 748 P3, Group 6, owner: Ziyao Lin)
//
// Integrated LC3 instruction-memory timing contract:
// Requests are sampled before the rising edge using input #1step.
// The selected response is driven after that same rising edge,
// and is observable at the following rising-edge sample.
// Sequence processing must not advance simulation time.
// Data and completion remain stable between requests.
// Power-on reset is supported; mid-test reset is not yet qualified.
// ****************************************************************************
bit first_transfer=1;

  task respond_and_wait_for_next_transfer(
       // Request information returned to the responder sequence (addr = fetch PC).
       output imem_initiator_s imem_initiator_struct,
       // Word chosen by the responder sequence for the previous request.
       input imem_responder_s imem_responder_struct
       );// pragma tbx xtf
    if (!first_transfer) begin
      // Respond after the request edge, without an extra clock delay.
      if ($realtime != request_sample_time)
        $fatal(1, "IMEM responder missed its response deadline");

      if (reset_i === 1'b0) begin
        Instr_dout_o     <= imem_responder_struct.instr;
        complete_instr_o <= 1'b1;
      end
    end

    do @(request_cb);
    while ((request_cb.reset_i !== 1'b0) ||
           (request_cb.instrmem_rd_i !== 1'b1));

    if ($isunknown(request_cb.pc_i))
      $fatal(1, "IMEM request address contains X/Z");

    request_sample_time = $realtime;
    request_addr = request_cb.pc_i;

    imem_initiator_struct.addr = request_cb.pc_i;
    imem_initiator_struct.instr = request_cb.Instr_dout_i;
    first_transfer = 0;
  endtask
// pragma uvmf custom respond_and_wait_for_next_transfer end

 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

