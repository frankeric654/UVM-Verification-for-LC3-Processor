package mem_access_env_pkg;
    import uvm_pkg::*;
    import mem_access_in_pkg::*;
    import mem_access_out_pkg::*;
    import lc3_prediction_pkg::*;
    `include "uvm_macros.svh"

    `include "src/mem_access_predictor.svh"
    `include "src/mem_access_scoreboard.svh"
    `include "src/mem_access_env_configuration.svh"
    `include "src/mem_access_environment.svh"
endpackage : mem_access_env_pkg
