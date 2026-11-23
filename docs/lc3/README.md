# LC3 top-level integration

[繁體中文](README_zh-TW.md)

This branch adds the missing shared LC3 bench on top of team main `4ff9e12`.
Both simulation tops and all six stage environments are implemented and have
compiled and executed together with the supplied LC3 RTL. **The combined smoke
run currently fails stage comparisons; this is an integration handoff, not a
claim of passing processor verification or final project completion.**

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
Reset clears handshake outputs, not the array. This is **not a dmem UVM agent**,
and has not been independently validated for every LC3 protocol scenario.
Replace it with the team's final dmem agent; do not drive both at once.

## Run

Use authorized local copies of the instructor's eight RTL files (including
`data_defs.v`) and a UVMF distribution. Neither is copied into this contribution.
The checked-in `verification_ip/prediction_packages/lc3_prediction_pkg` is used.
Questa UVM 1.2 headers and precompiled library must match.

```bash
module load questa/2024.2
export LC3_RTL_DIR=/path/to/LC3_veloce_encrypted
export UVMF_HOME=/path/to/UVMF_2023.3
export QUESTA_HOME=/path/to/questasim
python project_benches/lc3/sim/run.py --seed 1 --cycles 300
```

CLI options `--rtl-dir`, `--uvmf-home`, `--questa-home` override those variables.
Use `--compile-only` for compilation, or `--out /tmp/lc3-run` to put all compiled
libraries/logs outside the checkout. Default output is the ignored `sim/build`.
The runner selects `lc3_smoke_test` and loads both `hdl_top` and `hvl_top`.
Simulator warnings about virtual interfaces containing interface ports are
retained. A successful simulator process alone is not treated as a passing test.

See [VALIDATION.md](VALIDATION.md) for measured results and open failures.
