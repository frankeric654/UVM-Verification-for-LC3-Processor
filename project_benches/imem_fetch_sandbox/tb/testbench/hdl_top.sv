//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------                     
//               
// Description: This top level module instantiates all synthesizable
//    static content.  This and tb_top.sv are the two top level modules
//    of the simulation.  
//
//    This module instantiates the following:
//        DUT: The Design Under Test
//        Interfaces:  Signal bundles that contain signals connected to DUT
//        Driver BFM's: BFM's that actively drive interface signals
//        Monitor BFM's: BFM's that passively monitor interface signals
//
//----------------------------------------------------------------------

//----------------------------------------------------------------------
//

module hdl_top;

import imem_fetch_sandbox_parameters_pkg::*;
import uvmf_base_pkg_hdl::*;

  // pragma attribute hdl_top partition_module_xrtl                                            
// pragma uvmf custom clock_generator begin
  bit clk;
  // Instantiate a clk driver 
  // tbx clkgen
  initial begin
    clk = 0;
    #0ns;
    forever begin
      clk = ~clk;
      #5ns;
    end
  end
// pragma uvmf custom clock_generator end

// pragma uvmf custom reset_generator begin
  bit rst;
  // Reset is held for 5 clocks and released with a nonblocking assignment
  // right after a rising edge: the LC3 still sees reset=1 at that edge and
  // reset=0 for the whole following cycle, so the falling-edge monitors and
  // the imem responder see that first cycle as well.
  initial begin
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst <= 1'b0;
  end
// pragma uvmf custom reset_generator end

  // pragma uvmf custom module_item_additional begin
  // pragma uvmf custom module_item_additional end

  // Instantiate the signal bundle, monitor bfm and driver bfm for each interface.
  // The signal bundle, _if, contains signals to be connected to the DUT.
  // The monitor, monitor_bfm, observes the bus, _if, and captures transactions.
  // The driver, driver_bfm, drives transactions onto the bus, _if.
  fetch_in_if  fetch_env_fetch_in_agent_bus(
     // pragma uvmf custom fetch_env_fetch_in_agent_bus_connections begin
     .clock(clk), .reset(rst)
     // pragma uvmf custom fetch_env_fetch_in_agent_bus_connections end
     );
  fetch_out_if  fetch_env_fetch_out_agent_bus(
     // pragma uvmf custom fetch_env_fetch_out_agent_bus_connections begin
     .clock(clk), .reset(rst)
     // pragma uvmf custom fetch_env_fetch_out_agent_bus_connections end
     );
  imem_if  imem_agent_bus(
     // pragma uvmf custom imem_agent_bus_connections begin
     .clock(clk), .reset(rst)
     // pragma uvmf custom imem_agent_bus_connections end
     );
  fetch_in_monitor_bfm  fetch_env_fetch_in_agent_mon_bfm(fetch_env_fetch_in_agent_bus.monitor_port);
  fetch_out_monitor_bfm  fetch_env_fetch_out_agent_mon_bfm(fetch_env_fetch_out_agent_bus.monitor_port);
  imem_monitor_bfm  imem_agent_mon_bfm(imem_agent_bus.monitor_port);
  imem_driver_bfm  imem_agent_drv_bfm(imem_agent_bus.responder_port);

  // pragma uvmf custom dut_instantiation begin
  // LC3 DUT. The instruction-memory ports connect directly to the imem
  // agent's signal bundle (the agent is the RESPONDER).
  // SANDBOX ONLY: there is no dmem agent in this bench; reads return 0 and
  // every data access completes at once (complete_data tied high). The team's
  // lc3 bench connects these ports to the dmem agent instead.
  wire [15:0] sandbox_Data_addr;
  wire [15:0] sandbox_Data_din;
  wire        sandbox_Data_rd;
  LC3 DUT (
    .clock          (clk),
    .reset          (rst),
    .pc             (imem_agent_bus.pc),
    .instrmem_rd    (imem_agent_bus.instrmem_rd),
    .Instr_dout     (imem_agent_bus.Instr_dout),
    .complete_instr (imem_agent_bus.complete_instr),
    .Data_addr      (sandbox_Data_addr),
    .Data_din       (sandbox_Data_din),
    .Data_rd        (sandbox_Data_rd),
    .Data_dout      (16'h0000),
    .complete_data  (1'b1)
  );
  // Fetch stage observation. These are LC3-internal nets; one-way continuous
  // assignments guarantee the monitor-only interfaces can never drive them.
  assign fetch_env_fetch_in_agent_bus.enable_updatePC = DUT.enable_updatePC;
  assign fetch_env_fetch_in_agent_bus.enable_fetch    = DUT.enable_fetch;
  assign fetch_env_fetch_in_agent_bus.br_taken        = DUT.br_taken;
  assign fetch_env_fetch_in_agent_bus.taddr           = DUT.pcout;          // Fetch.taddr <- Execute.pcout
  assign fetch_env_fetch_out_agent_bus.pc             = DUT.pc;
  assign fetch_env_fetch_out_agent_bus.npc_out        = DUT.npc_out_fetch;  // Fetch.npc_out
  assign fetch_env_fetch_out_agent_bus.instrmem_rd    = DUT.instrmem_rd;

  // Simulation-only bring-up checks and a short CSV trace. The original RTL
  // and instructor functions are not changed. Raw four-state pins are used.
  integer p3_trace_fd;
  integer p3_cycles = 0;
  integer p3_rd0_when_disabled = 0;
  bit p3_strict_rd_z = 0;
  string p3_trace_path;
  initial begin
    // Default verification basis: as-delivered encrypted DUT + instructor
    // prediction model. Both use 0 for disabled instrmem_rd. The written
    // DesignSpec (page 11) instead requires Z. Never silently equate them:
    // retain the four-state pin observation, count every 0/Z variance and
    // report a warning. Strict written-spec enforcement is opt-in and FAILS
    // if the DUT produces 0 on a disabled cycle. No DUT output is modified.
    p3_strict_rd_z = $test$plusargs("P3_STRICT_FETCH_Z");
    if (!$value$plusargs("P3_TRACE_FILE=%s", p3_trace_path))
      p3_trace_path = "p3_smoke_trace.csv";
    p3_trace_fd = $fopen(p3_trace_path, "w");
    if (!p3_trace_fd)
      uvm_pkg::uvm_report_fatal("P3_TRACE", {"Cannot open ", p3_trace_path});
    $fdisplay(p3_trace_fd, "cycle,time,reset,pc,rd,instr,complete,enable_fetch,update_pc,enable_decode,br_taken,taddr,mem_state");
  end

  always @(negedge clk) begin
    if (rst === 1'b0) begin
      p3_cycles = p3_cycles + 1;
      // DesignSpec pp.10-11: asynchronous 1 when enabled, Z when disabled.
      if (DUT.enable_fetch === 1'b1) begin
        if (DUT.instrmem_rd !== 1'b1)
          uvm_pkg::uvm_report_error("FETCH_RD_PROTOCOL", $sformatf("enable_fetch=1 but instrmem_rd=%b", DUT.instrmem_rd));
      end else if (DUT.enable_fetch === 1'b0) begin
        if (DUT.instrmem_rd === 1'b0) begin
          p3_rd0_when_disabled = p3_rd0_when_disabled + 1;
          if (p3_strict_rd_z) begin
            uvm_pkg::uvm_report_error("FETCH_RD_PROTOCOL", "STRICT DesignSpec: enable_fetch=0 requires Z, but instructor DUT drives 0. Use the default functional mode to continue testing the as-delivered DUT/model while recording this difference.");
          end else if (p3_rd0_when_disabled == 1) begin
            // Known DUT+model vs written DesignSpec discrepancy. Deliberately
            // separate functional check status from written-spec conformance.
            // The UVM monitor still normalizes VALID idle 0/Z to logical no-read;
            // raw 0 is never overwritten or presented as Z.
            uvm_pkg::uvm_report_warning("FETCH_RD_SPEC_DISCREPANCY", "In instructor-DUT/model functional mode, idle instrmem_rd=0 is accepted as NO READ; written DesignSpec instead requires Z. Every such sample is counted. This is NOT written-spec compliance.");
          end
        end else if (DUT.instrmem_rd !== 1'bz) begin
          uvm_pkg::uvm_report_error("FETCH_RD_PROTOCOL", $sformatf("DesignSpec requires Z when enable_fetch=0, observed %b", DUT.instrmem_rd));
        end
      end else begin
        uvm_pkg::uvm_report_error("FETCH_RD_PROTOCOL", "enable_fetch contains X/Z");
      end
      // Bound the trace even in long tests. The short test is captured in full.
      if (p3_cycles <= 500) begin
        $fdisplay(p3_trace_fd, "%0d,%0t,%b,%h,%b,%h,%b,%b,%b,%b,%b,%h,%h",
          p3_cycles, $time, rst, DUT.pc, DUT.instrmem_rd, imem_agent_bus.Instr_dout,
          imem_agent_bus.complete_instr, DUT.enable_fetch, DUT.enable_updatePC,
          DUT.enable_decode, DUT.br_taken, DUT.pcout, DUT.mem_state);
        $fflush(p3_trace_fd);
      end
    end
  end
  final begin
    // Available in the transcript even when the UVM report phase has ended.
    $display("P3_FETCH_RD_SPEC_SUMMARY disabled_rd0_samples=%0d strict_mode=%0d", p3_rd0_when_disabled, p3_strict_rd_z);
    if (p3_trace_fd) $fclose(p3_trace_fd);
  end
  // pragma uvmf custom dut_instantiation end

  initial begin      // tbx vif_binding_block 
    import uvm_pkg::uvm_config_db;
    // The monitor_bfm and driver_bfm for each interface is placed into the uvm_config_db.
    // They are placed into the uvm_config_db using the string names defined in the parameters package.
    // The string names are passed to the agent configurations by test_top through the top level configuration.
    // They are retrieved by the agents configuration class for use by the agent.
    uvm_config_db #( virtual fetch_in_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , fetch_env_fetch_in_agent_BFM , fetch_env_fetch_in_agent_mon_bfm ); 
    uvm_config_db #( virtual fetch_out_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , fetch_env_fetch_out_agent_BFM , fetch_env_fetch_out_agent_mon_bfm ); 
    uvm_config_db #( virtual imem_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , imem_agent_BFM , imem_agent_mon_bfm ); 
    uvm_config_db #( virtual imem_driver_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , imem_agent_BFM , imem_agent_drv_bfm  );
  end

endmodule

// pragma uvmf custom external begin
// pragma uvmf custom external end

