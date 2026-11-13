# Fetch Verification Environment

ECE 748 Project 3 - Group 6

## Components

- fetch_in_pkg: Passive Fetch input agent
- fetch_out_pkg: Passive Fetch output agent
- fetch_env_pkg: Fetch predictor, scoreboard, and environment

## Dependencies

- UVM / UVMF
- Instructor-provided lc3_prediction_pkg (fetch_model)
- LC3-level testbench integration

## Validation

Tested in a standalone LC3 testbench using Siemens Questa.

- 37,960 / 37,960 targeted legal instruction encodings
- 83,102 Fetch scoreboard matches
- 0 mismatches and 0 UVM errors

These results are from the standalone verification environment,
not the final integrated Group 6 testbench.

## Integration Notes

- Connect Fetch agents to the corresponding LC3 signals.
- Include lc3_prediction_pkg in the compilation dependencies.
- Fetch agents are passive monitoring agents.
- Final integration and regression must be validated separately.
- Known discrepancy: inactive instrmem_rd=0 in the provided
  DUT/model, while the written specification requires Z.
