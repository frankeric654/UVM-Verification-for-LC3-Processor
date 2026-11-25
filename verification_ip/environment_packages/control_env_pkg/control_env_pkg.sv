package control_env_pkg;
    import uvm_pkg::*;
    import control_in_pkg::*;
    import control_out_pkg::*;
    `include "uvm_macros.svh"
    `uvm_analysis_imp_decl(_cov_in)
    `uvm_analysis_imp_decl(_cov_out)
    `include "control_env_configuration.svh"
    `include "control_reference_model.svh"
    `include "control_predictor.svh"
    `include "control_scoreboard.svh"
    `include "control_memory_coverage.svh"
    `include "control_environment.svh"
endpackage
