
package execute_env_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Import Execute input/output transaction classes.
  import execute_in_pkg::*;
  import execute_out_pkg::*;

  // Import the instructor-provided reference models.
  import lc3_prediction_pkg::*;

  // Execute configuration.
  `include "execute_configuration.svh"

  // Execute predictor.
  `include "execute_predictor.svh"

  // Execute scoreboard.
  `include "execute_scoreboard.svh"

  // Execute functional coverage.
  `include "execute_coverage.svh"

  // Execute environment.
  `include "execute_env.svh"

endpackage
