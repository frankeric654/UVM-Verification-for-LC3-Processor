// Aggregate the team's existing environments without replacing their checkers.
class lc3_environment extends uvm_env;
  `uvm_component_utils(lc3_environment)
  fetch_environment fetch_env;
  decode_environment decode_env;
  execute_env_pkg::execute_env execute_env;
  mem_access_environment mem_access_env;
  writeback_environment writeback_env;
  control_environment control_env;
  imem_agent imem;
  fetch_env_configuration fetch_cfg;
  imem_configuration imem_cfg;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    string names[] = '{"lc3_fetch_in", "lc3_fetch_out"};
    uvmf_active_passive_t activities[] = '{PASSIVE, PASSIVE};
    super.build_phase(phase);
    fetch_cfg = fetch_env_configuration::type_id::create("fetch_cfg");
    fetch_cfg.initialize(NA, {get_full_name(), ".fetch_env"}, names, null, activities);
    fetch_env = fetch_environment::type_id::create("fetch_env", this);
    fetch_env.set_config(fetch_cfg);
    decode_env = decode_environment::type_id::create("decode_env", this);
    execute_env = execute_env_pkg::execute_env::type_id::create("execute_env", this);
    mem_access_env = mem_access_environment::type_id::create("mem_access_env", this);
    writeback_env = writeback_environment::type_id::create("writeback_env", this);
    control_env = control_environment::type_id::create("control_env", this);
    imem_cfg = imem_configuration::type_id::create("imem_cfg");
    imem_cfg.initialize(ACTIVE, {get_full_name(), ".imem"}, "lc3_imem");
    imem_cfg.initiator_responder = RESPONDER;
    imem = imem_agent::type_id::create("imem", this);
    imem.set_config(imem_cfg);
  endfunction
endclass
