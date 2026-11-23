package decode_out_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "src/decode_out_transaction.svh"
    `include "src/decode_out_coverage.svh"
    `include "src/decode_out_configuration.svh"
    // Output agent is passive: no driver implementation is required.
    `include "src/decode_out_monitor.svh"

    `include "src/decode_out_agent.svh"
    

endpackage