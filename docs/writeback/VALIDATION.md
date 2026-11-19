# WB validation record — November 11, 2026

Simulator: Questa 2024.2, matching bundled UVM 1.2 library and headers.
The instructor prediction package is supplied externally and is unmodified.

## Compilation

The complete WB source, coverage subscriber, and two test tops compile with
**0 errors and 0 warnings**. The connection fragment also compiles alongside the
instructor's encrypted LC3 RTL with **0 errors and 0 warnings** in a temporary
probe top. That compile check is not LC3 functional simulation.

## Infrastructure regression

All seven cases passed their expected diagnostic checks. Negative cases are
successful because the expected UVM error is detected, not because the run is
error-free. All seven UCDB artifacts were verified to exist and be nonempty.

| Case | UVM errors | Expected result |
| --- | ---: | --- |
| smoke | 0 | 78 edges, 190 field checks, no mismatch |
| corrupt_d1 | 50 | WB_MISMATCH detects corrupted known read data |
| corrupt_psr | 24 | WB_MISMATCH detects corrupted known flags |
| scoreboard | 0 | Actual-first pairing, clone isolation, masked unknowns |
| scoreboard_x | 1 | WB_MISMATCH detects actual X against a known expected value |
| pending | 1 | WB_PENDING detects an unpaired expected transaction |
| duplicate | 1 | WB_DUPLICATE detects a repeated expected edge |

All cases have UVM_FATAL=0. Final script exit status is 0. Reproduce with
`bash scripts/writeback/regress.sh` after loading the Questa module/license.
The run's artifacts are in `/tmp/ece748-wb-regression-complete` (temporary storage):
`compile.log`, each case's log/UCDB, and `wb-functional-coverage.txt`.
The normal smoke report has covergroup metric **87.22%**, with **68/81 bins hit
(83.95%)**; the two percentages use different aggregation rules. These are WB
smoke-fixture coverage metrics, not LC3 instruction coverage or project progress.

The normal smoke fixture is independent behavioral test logic, not instructor
RTL. Its normal run completes 78 paired edges, 190 enabled field comparisons,
0 mismatches and 4 wholly unchecked pairs. The intentional unknown-data write
produces one `WB_UNDEFINED_WRITE` warning. Fully unchecked reset/startup samples
are visible rather than being treated as verified state.

The simulator emits warning 8887 for virtual BFMs containing interface ports;
this structure successfully executes in Questa 2024.2. Scoreboard-only runs may
also report code-coverage optimization warning 13408 for unused design units.
These simulator warnings are distinct from the UVM error checks. Portability
of this BFM structure to other simulators has not been established.

## Coverage limits

Only the non-corrupted smoke UCDB is used for the WB coverage report. Fault
injection runs are not used to claim functional coverage. Stimulus coverpoints
are not proof that the corresponding behavior is correct. In particular, reset
assertion/deassertion bins do not verify reset values/retention: that contract is
still unresolved and predictor knowledge is conservatively invalidated.

This regression is a WB verification-infrastructure check. Team LC3-level tests,
instruction coverage, merged test plan/report, integration paths/UVMF wrappers,
and actual LC3 bug documentation remain required for Project 3 completion.

## Configuration object update — November 11, 2026

Added plain-UVM input/output configuration objects and routed the existing BFM
handles through agent configuration to monitor configuration. No UVMF migration.
The updated complete source and test tops compile with zero errors/warnings.

Targeted regression:
`WB_TEST_SUITE=configuration WB_BUILD_DIR=/tmp/ece748-wb-configuration bash scripts/writeback/regress.sh`

- Normal smoke: 78 pairs, 190 field checks, zero mismatch/error/fatal.
- Missing input configuration: exactly one `NO_CONFIG` fatal at time zero.
- Configuration with null input BFM: exactly one `NO_BFM` fatal at time zero.

All three targeted cases passed; script exit status 0. The six other previously
validated fault/scoreboard cases were not rerun for this wiring-only change.
The default regression now includes all nine cases. Current logs/UCDB/report are
in `/tmp/ece748-wb-configuration`.

## Shared reset timing — November 13, 2026

The team's `imem_coverage` HDL top holds active-high reset for five rising
edges and releases it with NBA. The WB smoke now uses that same sequence at
startup and mid-test via `apply_reset()`. `drive()` no longer releases reset.
The production passive WB agents continue observing the LC3's shared reset;
no second reset source or UVMF dependency was added.

Command: `WB_TEST_SUITE=configuration WB_BUILD_DIR=/tmp/ece748-wb-team-reset bash scripts/writeback/regress.sh`

- Complete source/test-top compile: 0 errors, 0 warnings.
- Smoke: 86 edge pairs, 190 field checks, 0 mismatches, 12 wholly unchecked
  reset/startup pairs, UVM_ERROR=0 and UVM_FATAL=0.
- Missing configuration and null BFM initialization checks: both passed with
  their expected NO_CONFIG/NO_BFM fatal diagnostics.
- Script exit status: 0. Logs/UCDB/report: `/tmp/ece748-wb-team-reset`.

The larger pair count reflects longer reset pulses, not added state verification.
No predictor/scoreboard behavior changed. Prior fault-injection/scoreboard
results above are historical and were not rerun for this reset-stimulus change.
Matching the reset waveform or the senior monitor's wait-for-reset task does not
define register/PSR reset values. The WB reset-state/retention limitation remains.
