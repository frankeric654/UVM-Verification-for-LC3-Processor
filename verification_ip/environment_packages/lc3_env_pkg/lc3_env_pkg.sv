package lc3_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // UVMF types required by the Fetch configuration.
  import uvmf_base_pkg::*;

  // Import the environment packages for each LC3 pipeline stage.
  import fetch_env_pkg::*;
  import decode_env_pkg::*;
  import execute_env_pkg::*;
  import mem_access_env_pkg::*;
  import writeback_env_pkg::*;
  import control_env_pkg::*;

  // Import the existing instruction memory responder agent.
  import imem_pkg::*;

  // Top-level LC3 environment configuration.
  `include "src/lc3_env_configuration.svh"

  // Top-level LC3 environment.
  `include "src/lc3_environment.svh"

endpackage : lc3_env_pkg
