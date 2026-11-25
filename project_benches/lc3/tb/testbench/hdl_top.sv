// Shared static LC3 bench. All stage agents observe; only memories respond.
module hdl_top;
  timeunit 1ns;
  timeprecision 1ps;
  import uvm_pkg::*;
  import uvmf_base_pkg_hdl::*;
  logic clock = 0;
  logic reset = 1;
  always #5ns clock = ~clock;
  initial begin
    repeat (5) @(posedge clock);
    reset <= 0;
  end

  imem_if imem_bus(.clock(clock), .reset(reset), .pc(), .instrmem_rd(), .Instr_dout(), .complete_instr());
  wire [15:0] data_addr, data_din;
  wire data_rd;
  logic [15:0] data_dout;
  logic complete_data;
  LC3 dut(.clock(clock), .reset(reset), .pc(imem_bus.pc),
    .instrmem_rd(imem_bus.instrmem_rd), .Instr_dout(imem_bus.Instr_dout),
    .complete_instr(imem_bus.complete_instr), .Data_addr(data_addr),
    .Data_din(data_din), .Data_rd(data_rd), .Data_dout(data_dout),
    .complete_data(complete_data));
  mem_access_assertions mem_access_checks (
    .clock(clock),
    .reset(reset),
    .complete_data(complete_data),
    .mem_state(dut.mem_state),
    .IR_Exec(dut.IR_Exec),
    .M_Control(dut.Mem_Control_out),
    .M_Data(dut.M_Data),
    .M_Addr(dut.pcout),
    .Data_dout(data_dout),
    .Data_addr(data_addr),
    .Data_din(data_din),
    .Data_rd(data_rd),
    .memout(dut.memout),
    .enable_updatePC(dut.enable_updatePC),
    .enable_fetch(dut.enable_fetch),
    .enable_decode(dut.enable_decode),
    .enable_execute(dut.enable_execute),
    .enable_writeback(dut.enable_writeback),
    .bypass_alu_1(dut.bypass_alu_1),
    .bypass_alu_2(dut.bypass_alu_2),
    .bypass_mem_1(dut.bypass_mem_1),
    .bypass_mem_2(dut.bypass_mem_2)
  );
  lc3_dmem_model dmem(.clock(clock), .reset(reset), .mem_state(dut.mem_state),
    .addr(data_addr), .din(data_din), .rd(data_rd),
    .dout(data_dout), .complete(complete_data));
  imem_monitor_bfm imem_mon(imem_bus.monitor_port);
  imem_driver_bfm imem_drv(imem_bus.responder_port);

  fetch_in_if fetch_in_bus(.clock(clock), .reset(reset), .enable_updatePC(), .enable_fetch(), .br_taken(), .taddr());
  fetch_out_if fetch_out_bus(.clock(clock), .reset(reset), .pc(), .npc_out(), .instrmem_rd());
  assign fetch_in_bus.enable_updatePC = dut.enable_updatePC;
  assign fetch_in_bus.enable_fetch = dut.enable_fetch;
  assign fetch_in_bus.br_taken = dut.br_taken;
  assign fetch_in_bus.taddr = dut.pcout;
  assign fetch_out_bus.pc = dut.pc;
  assign fetch_out_bus.npc_out = dut.npc_out_fetch;
  assign fetch_out_bus.instrmem_rd = dut.instrmem_rd;
  fetch_in_monitor_bfm fetch_in_bfm(fetch_in_bus.monitor_port);
  fetch_out_monitor_bfm fetch_out_bfm(fetch_out_bus.monitor_port);

  decode_in_if decode_in_bus(.clock(clock), .reset(reset));
  decode_out_if decode_out_bus(.clock(clock), .reset(reset));
  assign decode_in_bus.enable_decode = dut.enable_decode;
  assign decode_in_bus.IMem_dout = imem_bus.Instr_dout;
  assign decode_in_bus.npc_in = dut.npc_out_fetch;
  assign decode_out_bus.IR = dut.IR;
  assign decode_out_bus.npc_out = dut.npc_out_dec;
  assign decode_out_bus.E_control = dut.E_Control;
  assign decode_out_bus.W_control = dut.W_Control;
  assign decode_out_bus.Mem_control = dut.Mem_Control;
  decode_in_monitor_bfm decode_in_bfm(decode_in_bus.MONITOR);
  decode_out_monitor_bfm decode_out_bfm(decode_out_bus.MONITOR);

  execute_in_if execute_in_bus(.clock(clock), .reset(reset),
    .enable_execute(dut.enable_execute), .E_Control(dut.E_Control),
    .bypass_alu_1(dut.bypass_alu_1), .bypass_alu_2(dut.bypass_alu_2),
    .bypass_mem_1(dut.bypass_mem_1), .bypass_mem_2(dut.bypass_mem_2),
    .IR(dut.IR), .npc(dut.npc_out_dec), .Mem_Control_in(dut.Mem_Control),
    .W_Control_in(dut.W_Control), .Mem_Bypass_Val(dut.memout),
    .VSR1(dut.VSR1), .VSR2(dut.VSR2));
  execute_out_if execute_out_bus(.clock(clock), .aluout(dut.aluout),
    .pcout(dut.pcout), .W_Control_out(dut.W_Control_out),
    .Mem_Control_out(dut.Mem_Control_out), .NZP(dut.NZP), .IR_Exec(dut.IR_Exec),
    .sr1(dut.sr1), .sr2(dut.sr2), .dr(dut.dr), .M_Data(dut.M_Data));
  execute_in_monitor_bfm execute_in_bfm(execute_in_bus);
  execute_out_monitor_bfm execute_out_bfm(execute_out_bus);

  mem_access_in_if mem_in_bus(.clock(clock), .reset(reset));
  mem_access_out_if mem_out_bus(.clock(clock), .reset(reset));
  assign mem_in_bus.mem_state = dut.mem_state;
  assign mem_in_bus.M_Control = dut.Mem_Control_out;
  assign mem_in_bus.M_Data = dut.M_Data;
  assign mem_in_bus.M_Addr = dut.pcout;
  assign mem_in_bus.Data_dout = data_dout;
  assign mem_out_bus.Data_addr = data_addr;
  assign mem_out_bus.Data_din = data_din;
  assign mem_out_bus.Data_rd = data_rd;
  assign mem_out_bus.memout = dut.memout;
  mem_access_in_monitor_bfm mem_in_bfm(mem_in_bus.MONITOR);
  mem_access_out_monitor_bfm mem_out_bfm(mem_out_bus.MONITOR);

  // WB's existing adapter binds directly to the actual WB ports.
  `include "writeback_connections.svh"

  control_in_if control_in_bus(.clock(clock), .reset(reset),
    .complete_data(complete_data), .complete_instr(imem_bus.complete_instr),
    .IR(dut.IR), .IR_Exec(dut.IR_Exec), .Instr_dout(imem_bus.Instr_dout),
    .NZP(dut.NZP), .psr(dut.psr));
  control_out_if control_out_bus(.clock(clock), .reset(reset),
    .enable_updatePC(dut.enable_updatePC), .enable_fetch(dut.enable_fetch),
    .enable_decode(dut.enable_decode), .enable_execute(dut.enable_execute),
    .enable_writeback(dut.enable_writeback), .bypass_alu_1(dut.bypass_alu_1),
    .bypass_alu_2(dut.bypass_alu_2), .bypass_mem_1(dut.bypass_mem_1),
    .bypass_mem_2(dut.bypass_mem_2), .mem_state(dut.mem_state), .br_taken(dut.br_taken));
  control_in_monitor_bfm control_in_bfm(control_in_bus);
  control_out_monitor_bfm control_out_bfm(control_out_bus);

  // Questa resolves virtual driver types even for classes never constructed.
  // Keep these compatibility instances on PRIVATE, disconnected buses. No
  // driver agent is active and none of these BFMs can drive DUT stage signals.
  fetch_in_if unused_fetch_in_bus(.clock(clock), .reset(reset), .enable_updatePC(), .enable_fetch(), .br_taken(), .taddr());
  fetch_out_if unused_fetch_out_bus(.clock(clock), .reset(reset), .pc(), .npc_out(), .instrmem_rd());
  decode_in_if unused_decode_in_bus(.clock(clock), .reset(reset));
  fetch_in_driver_bfm unused_fetch_in_drv(unused_fetch_in_bus.initiator_port);
  fetch_out_driver_bfm unused_fetch_out_drv(unused_fetch_out_bus.initiator_port);
  decode_in_driver_bfm unused_decode_in_drv(unused_decode_in_bus.DRIVER);

  // Called once by hvl_top BEFORE run_test, avoiding time-zero initial races.
  function void configure_bfms();
    decode_env_pkg::decode_env_configuration dec_cfg;
    mem_access_env_pkg::mem_access_env_configuration mem_cfg;
    control_env_pkg::control_env_configuration ctrl_cfg;
    uvm_config_db#(virtual fetch_in_monitor_bfm)::set(null,
      UVMF_VIRTUAL_INTERFACES, "lc3_fetch_in", fetch_in_bfm);
    uvm_config_db#(virtual fetch_out_monitor_bfm)::set(null,
      UVMF_VIRTUAL_INTERFACES, "lc3_fetch_out", fetch_out_bfm);
    uvm_config_db#(virtual imem_monitor_bfm)::set(null,
      UVMF_VIRTUAL_INTERFACES, "lc3_imem", imem_mon);
    uvm_config_db#(virtual imem_driver_bfm)::set(null,
      UVMF_VIRTUAL_INTERFACES, "lc3_imem", imem_drv);

    uvm_config_db#(virtual decode_out_monitor_bfm)::set(null,
      "uvm_test_top.env.decode_env.agent_out", "monitor_bfm", decode_out_bfm);
    uvm_config_db#(virtual mem_access_in_monitor_bfm)::set(null,
      "uvm_test_top.env.mem_access_env.agent_in", "monitor_bfm", mem_in_bfm);
    uvm_config_db#(virtual mem_access_out_monitor_bfm)::set(null,
      "uvm_test_top.env.mem_access_env.agent_out", "monitor_bfm", mem_out_bfm);
    dec_cfg = new("decode_config");
    dec_cfg.config_in.is_active = UVM_PASSIVE;
    dec_cfg.config_out.is_active = UVM_PASSIVE;
    dec_cfg.config_in.monitor_bfm = decode_in_bfm;
    dec_cfg.config_out.monitor_bfm = decode_out_bfm;
    uvm_config_db#(decode_env_pkg::decode_env_configuration)::set(null,
      "uvm_test_top.env.decode_env", "config", dec_cfg);
    mem_cfg = new("mem_access_config");
    mem_cfg.config_in.is_active = UVM_PASSIVE;
    mem_cfg.config_out.is_active = UVM_PASSIVE;
    mem_cfg.config_in.monitor_bfm = mem_in_bfm;
    mem_cfg.config_out.monitor_bfm = mem_out_bfm;
    uvm_config_db#(mem_access_env_pkg::mem_access_env_configuration)::set(null,
      "uvm_test_top.env.mem_access_env", "config", mem_cfg);

    uvm_config_db#(virtual execute_in_monitor_bfm)::set(null,
      "uvm_test_top.env.execute_env.in_agent.monitor", "monitor_bfm", execute_in_bfm);
    uvm_config_db#(virtual execute_out_monitor_bfm)::set(null,
      "uvm_test_top.env.execute_env.out_agent.monitor", "monitor_bfm", execute_out_bfm);
    configure_writeback_bfms("uvm_test_top.env.writeback_env");

    ctrl_cfg = new("control_config");
    ctrl_cfg.control_in_config.monitor_bfm = control_in_bfm;
    ctrl_cfg.control_out_config.monitor_bfm = control_out_bfm;
    uvm_config_db#(control_env_pkg::control_env_configuration)::set(null,
      "uvm_test_top.env.control_env", "configuration", ctrl_cfg);
    uvm_config_db#(control_in_pkg::control_in_configuration)::set(null,
      "uvm_test_top.env.control_env.control_in_agent", "configuration", ctrl_cfg.control_in_config);
    uvm_config_db#(control_out_pkg::control_out_configuration)::set(null,
      "uvm_test_top.env.control_env.control_out_agent", "configuration", ctrl_cfg.control_out_config);
  endfunction
endmodule
