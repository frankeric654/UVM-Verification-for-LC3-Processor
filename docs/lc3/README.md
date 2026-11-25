# LC3 top-level integration

[繁體中文](README_zh-TW.md)

The shared LC3 environment compiles and runs all six stages.
Custom instruction coverage and Fetch behavior coverage are closed.
Known Control discrepancies and the missing formal DMEM responder
prevent final strict sign-off.

See [VALIDATION.md](VALIDATION.md) for measured results.

## Entry points

| File | Role |
| --- | --- |
| `project_benches/lc3/tb/testbench/hdl_top.sv` | Clock/reset, complete LC3 instance, all stage signal bundles/BFMs, memory connections, and configuration binding function |
| `project_benches/lc3/tb/testbench/hvl_top.sv` | Calls HDL binding function before `run_test()`; loads test package |
| `verification_ip/environment_packages/lc3_env_pkg/` | Builds Fetch, Decode, Execute, MemAccess, Writeback, Control and the existing IMem responder agent |
| `project_benches/lc3/tb/tests/lc3_test_pkg/` | Runs the IMem sequence, holds the test objection, checks all six comparison paths have activity |
| `project_benches/lc3/tb/testbench/lc3_dmem_model.sv` | Behavioral data-memory responder used for integration |
| `project_benches/lc3/sim/run.py` | Reproducible compile/simulation driver; returns failure for UVM errors/fatals, missing test completion, or simulator errors |

The two tops are peer modules loaded by the simulator. The UVM hierarchy is
`uvm_test_top.env.{fetch_env,decode_env,execute_env,mem_access_env,writeback_env,control_env,imem}`.
Test/env objects are created during UVM build, not instantiated as HDL modules.
All six stage agents are passive. Only memory response logic drives DUT inputs.

## Binding details

The teams use different APIs, so `hdl_top.configure_bfms()` adapts them explicitly:

- Fetch/IMem: UVMF virtual-interface registry, followed by configuration initialization in `lc3_environment`.
- Decode/MemAccess: environment configuration under key `config`; the agent-specific BFM registry entries are also supplied where required.
- Execute: virtual BFM handles under each monitor's `monitor_bfm` key.
- Writeback: reuses `integration/writeback/writeback_connections.svh` and its configuration function.
- Control: environment and agent configuration objects under key `configuration`.

Binding runs synchronously from `hvl_top` before `run_test`, avoiding unrelated
initial-block ordering. Stage observation signals come from the supplied LC3
nets/ports; no internal CPU enables or results are forced by this bench.

Some unused driver classes remain in the team's reusable packages. Questa
requires matching interface instances even though those classes are never
constructed. Compatibility driver BFMs are instantiated on separate private
buses; they are not connected to DUT observation buses or active stage agents.

## Minimal integration fixes to existing Decode source

1. Input agent now honors `configuration.is_active`, building/connecting its
   driver and sequencer only in active mode. The complete LC3 bench selects passive.
2. Output package no longer includes nonexistent driver/random-sequence files.
3. Output configuration removes references to a nonexistent driver BFM and
   rejects active mode. The output agent remains passive.

Predictors, scoreboards, supplied models, and RTL are not altered to hide the
observed comparison failures.

## Data-memory model limits

The model implements 65,536 16-bit words, initially zero. Stores update memory;
loads return its contents. It observes `mem_state` and address/read/write pins,
responds on falling edges, and produces a completion pulse with a response gap.
Read data is held between responses so indirect operations can use the pointer.
The full regression also runs a directed controller/memory target test that
exercises LDI/STI, branches, dependencies, representative data patterns, and
representative 0, 1, 2, 3, 6, and 10-cycle data-memory response delays.
It explicitly enables the zero-word NOP compatibility profile in the controller
reference model; cycle-by-cycle comparisons remain enabled. This profile still
needs a licensed regression rerun for confirmation. The reset `enable_fetch`
difference remains a known spec/RTL discrepancy.
Reset clears handshake outputs, not the array. This is **not a dmem UVM agent**,
and has not been independently validated for every LC3 protocol scenario.
Replace it with the team's final dmem agent; do not drive both at once.

## Run

Use the course Questa installation and compatible UVMF.

QUESTA_HOME can be discovered from vsim on PATH.
UVMF_HOME can be discovered from a unique compatible installation
under the Questa examples directory. Set it explicitly if ambiguous.

The runner prefers project_benches/lc3/rtl and falls back to
project_benches/project3/rtl. LC3_RTL_DIR overrides both.

From the repository root:

    cd project_benches/lc3/sim
    make help
    make compile
    make baseline
    make regress

| Command | Purpose |
| --- | --- |
| make compile | Compile all sources |
| make smoke | Strict single-seed smoke |
| make smoke-regress | Strict multi-seed smoke |
| make baseline | Known-issue baseline |
| make regress | Strict full regression |
| make characterize | Experimental full regression |
| ./regress.sh | Strict full regression |
| ./regress.sh --characterize | Characterization |

Standalone regress.sh exit codes:

- 0: strict PASS.
- 1: regression FAIL.
- 2: characterization completed, not sign-off.

GNU Make can return 2 for different recipe failures.
Always inspect regression_status.json and transcripts.

## Regression artifacts

Each run preserves test transcripts, individual UCDBs,
merged.ucdb, coverage_summary.txt, coverage_details.txt,
regression_status.json and timing information.

Functional failures do not prevent later tests from running.
Incomplete simulations cannot establish successful coverage.

Only the coverage summary is intended for course submission.
The detailed report remains available for internal bin checks.

## External coverage binding

The build accepts EXTRA_SV_SOURCES, EXTRA_VLOG_ARGS
and EXTRA_VOPT_TOPS.

From project_benches/lc3/sim:

    export EXTRA_SV_SOURCES="$(realpath ../../../docs/lc3/ta_bind_probe.sv)"
    export EXTRA_VLOG_ARGS="+define+LC3_TA_BIND_TEST"
    export EXTRA_VOPT_TOPS="lc3_ta_bind_top"
    ./regress.sh --characterize
    unset EXTRA_SV_SOURCES EXTRA_VLOG_ARGS EXTRA_VOPT_TOPS

The probe demonstrates external binding and is not included
in the default regression.

The instructor must supply the actual coverage source and top.

## Submission packaging

From the repository root:

    bash scripts/package_p3.sh --check

This checks the committed source archive without running Questa.

After final integration:

    bash scripts/package_p3.sh --final "$HOME/748/p3_submission"

Final packaging requires the formal DMEM package, top-level
sequence package, canonical RTL directory and strict regression PASS.

The archive excludes generated compilation libraries,
individual UCDBs and experimental build directories.
