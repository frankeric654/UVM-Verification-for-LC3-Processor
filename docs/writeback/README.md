# Writeback verification: implementation guide

[繁體中文](README_zh-TW.md)

Owner: Cheng-Wei (clin39). Working branch: `stage/writeback`.

## Current status — November 11, 2026

The WB contribution now has both passive agents, interfaces, clocking blocks,
BFMs, four-state transfer types, transactions, monitors, a predictor adapter,
scoreboard, functional coverage subscriber, and `writeback_environment`.
It is UVM 1.2 code; matching the team's generated UVMF configuration/wrappers
and connecting the complete LC3 environment remain integration tasks.
No driver or sequencer is created by either WB agent.

```text
in_agent  -> predictor -> scoreboard.expected_export
          -> coverage
out_agent             -> scoreboard.actual_export
```

## Configuration objects (plain UVM)

`writeback_in_configuration` and `writeback_out_configuration` extend uvm_object.
Each holds a virtual `monitor_bfm` handle. Creating the configuration does not
instantiate a BFM. The bench creates the two configuration objects, assigns the
existing HDL BFM handles, and places them in config_db under the corresponding
agent path using the key `configuration`. Each agent retrieves its configuration,
validates it, and forwards the same object to its child monitor. The monitor uses
`configuration.monitor_bfm` for sampling. Missing/null configuration reports
`NO_CONFIG`; a null BFM reports `NO_BFM` during initialization.

This replaces the former direct `config_db#(virtual ... BFM)` setting at monitor
paths. The integration helper and smoke bench have been updated together. These
are plain UVM configurations; no UVMF dependency or wrapper migration is imposed.
Both agents remain passive, so active-mode configuration is not exposed.

The targeted regression command is
`WB_TEST_SUITE=configuration bash scripts/writeback/regress.sh`; it runs the
normal smoke and the two configuration initialization-failure tests. The default
regression runs all nine cases. The new failure cases intentionally report one
fatal each, and the script verifies its ID and time-zero occurrence.

## Supplied model and observation contract

The adapter calls the instructor's unmodified
`lc3_prediction_pkg::writeback_model`. Supply the original package externally;
it is not copied into this public repository. Its register array is static and
shared: use only ONE WB predictor/model caller per simulation. Start a fresh
simulation for each test; constructing another environment does not reset it.

The model reads registers BEFORE applying the current write. Input fields,
output read addresses, and d1/d2 use rising-edge `input #1step` sampling. Output
PSR uses explicit `input #0`, in the Observed region after normal RTL NBA and
combinational updates. One output sample intentionally combines pre-write read
data and post-write flags. This replaces the earlier post-write read convention.
The current monitors check reads on clock edges, not every between-edge address
transition. The smoke test changes an address in NBA to exercise this distinction.

Both BFMs return the absolute edge time in picoseconds. Transactions carry it as
`edge_time_ps`; the scoreboard pairs by that key regardless of arrival order.
One clock domain and no more than one rising edge per picosecond are assumed.
The scoreboard clones incoming objects, compares enabled fields with case
inequality (`!==`, detecting unexpected X/Z), and reports duplicates, pending
transactions, and absence of meaningful comparisons at end of test.

## Unknown values, disabled writes and reset

The self-test reset timing now matches the team's `imem_coverage` HDL top:
active high for five rising edges, then released by a nonblocking assignment.
Both startup and mid-test reset use `apply_reset()`; `drive()` does not release
reset. At integration the passive WB agents simply observe the shared top-level
reset; five edges is a bench stimulus choice, not a requirement of the agents.
[Team reset source](https://github.com/frankeric654/UVM-Verification-for-LC3-Processor/blob/imem_coverage/project_benches/imem_fetch_sandbox/tb/testbench/hdl_top.sv).
This aligns stimulus timing only. Fetch's PC reset value does not define WB
register/PSR reset values. The senior WB monitor waits for reset release, and the
supplied WB model has no reset input; neither resolves WB's reset-state contract.


The supplied function uses two-state bit ports. `reg_known` records whether each
model register has a trustworthy complete value. The read check masks are captured
before this edge's write. Startup unknown registers are skipped; a valid write
makes a register checkable on later edges. A known expected value compared with
an actual X/Z is an error, not a skipped comparison.

Only selected write data, destination, enable and selection must be known for a
valid model write. Unused X data inputs do not prevent it. Disabled writes still
produce read predictions and retain the last meaningful expected PSR. An unknown
or unsupported enabled write is NOT fed into the two-state model as a valid write;
it invalidates knowledge of affected state and emits `WB_UNDEFINED_WRITE`.
Selection 11 is undefined by the supplied model and is not assumed to select npc.
The predictor never reads DUT state to compute expected values.

Reset behavior is not sufficiently specified by the provided WB text/model.
While reset is 1 or unknown, the adapter invalidates state knowledge, emits an
unchecked expected sample, and does not call the model. It does not assume that
reset clears registers or PSR. Later known writes reestablish checks. Consequently
this version does NOT verify reset values or register retention across reset;
resolve that contract before claiming reset coverage. Fully masked pairs are
counted in `unchecked_pairs` to make this limitation visible.

## Compile and infrastructure tests

Load your simulator/license environment first. On the NCSU installation:

```bash
source /etc/profile.d/modules.sh
module use /mnt/apps/modules/ece
module load mentor/questa/2024.2
bash scripts/writeback/compile.sh
bash scripts/writeback/regress.sh
```

Run from the repo root. Override `QUESTA_HOME` and `LC3_PREDICTION_DIR` if needed;
the latter defaults to `../lc3_prediction_pkg`. `WB_BUILD_DIR` optionally selects
an output directory; otherwise scripts create a directory under `/tmp`. No build
library is written to the repo. Scripts use matching UVM 1.2 headers/library.
The compile order is supplied prediction package, transfer types, interfaces,
BFMs, in/out UVM packages, environment package, then optional test files.

The smoke fixture is independently coded behavioral logic, NOT the supplied LC3
RTL and NOT final assignment simulation evidence. It exercises all registers and
three sources, disabled reads/writes, same-register read/write, overwrites, sign
boundaries, unused X data, an unknown write followed by reinitialization, NBA
read-address changes, and reset/reinitialization. Negative tests intentionally
corrupt d1/PSR. Additional scoreboard tests verify reversed arrival order, cloning,
masked startup values, detection of actual X, duplicate edges and unpaired edges.
The regression validates UVM report counts/IDs, not just simulator exit codes.
Logs and UCDB artifacts are saved in the printed build directory. Coverage is WB
functional coverage only; the team's instruction coverage and test plan remain
required. Results are recorded in [VALIDATION.md](VALIDATION.md).

## Connecting the team's complete LC3 bench

1. Compile the WB files in the order above, with each package's src include path.
2. Import `writeback_env_pkg` and create one `writeback_environment` as a child of
   the LC3 environment during build_phase, for example named `writeback_env`.
3. Include `integration/writeback/writeback_connections.svh` inside the HDL top.
   Define `WB_DUT_PATH` if the LC3 instance is not named `dut`. The connections
   target the actual WB module ports; its control is `W_Control_out` at LC3 level.
4. Before run_test(), call
   `configure_writeback_bfms("uvm_test_top.env.writeback_env")`, replacing that
   string with the actual environment path. If HDL/HVL tops are separate, call
   the function through the HDL top's hierarchy from the run_test initial block.
5. Run full LC3 instruction/data memory responders and initialize all registers
   through instructions. End stimulus and allow the final sampled edge to finish
   before dropping the test's objection. WB monitors do not hold objections.

The connection fragment compiles alongside the supplied encrypted LC3 RTL in a
temporary probe top (zero errors/warnings); it has not been simulated in the team's complete bench. Team instance paths, responder
ownership and UVMF wrappers are not yet established locally. Do not treat the
infrastructure regression as completion of the LC3-level assignment regression.
