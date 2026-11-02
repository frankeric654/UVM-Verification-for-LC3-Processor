// Keep four-state output values so the scoreboard can detect unexpected X/Z.
package writeback_out_types_pkg;
  typedef struct packed {
    logic [15:0] d1; // TopLevelLC3 wire VSR1
    logic [15:0] d2; // TopLevelLC3 wire VSR2
    logic [2:0]  psr;
  } writeback_out_transfer_t;
endpackage
