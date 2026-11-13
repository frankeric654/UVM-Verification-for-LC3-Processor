# IMem responder and instruction coverage — standalone reference

ECE 748 Project 3 / Group 6. **Reference source only**: these files are provided to help the group reuse a previously tested LC3-level Fetch/IMem sandbox implementation. They are **not** the final shared `lc3_env`, and this package is **not self-contained or directly runnable**.

## What is included

- `verification_ip/interface_packages/imem_pkg/` (33 files): active instruction-memory responder, transactions, constrained sequences, monitor, BFM, and the instruction coverage collector (`src/imem_transaction_coverage.svh`).
- `verification_ip/environment_packages/imem_fetch_sandbox_env_pkg/` (11 files): standalone UVMF environment and its YAML; for reference only, not the final `lc3_env`.
- `project_benches/imem_fetch_sandbox/` (39 files): standalone top-level testbench, stimulus sequences, factory-override tests, validation logic, and associated UVMF-generated build inputs. In particular, `tb/sequences/src/imem_fetch_sandbox_bench_sequence_base.svh` and `tb/tests/src/test_top.svh` contain logic useful for integration.
- `docs/imem/README.md`: this explanation.

**Not included:** the original `run_smoke.sh`, `run_family.sh`, their Python acceptance scripts and source checksums, simulation results, waveforms, UCDBs, instructor-supplied RTL or prediction models, or the previously submitted Fetch source. To reproduce the original v6 run exactly, use the user's archived complete v6 sandbox, not this handoff.

## Results recorded by the original v6 run on Grendel

- Targeted legal instruction encoding coverage: **37,960 / 37,960** (ALU 9,280; Memory 24,576; Control 4,104).
- Fetch scoreboard: **83,102 matches, 0 mismatches**; **0 UVM errors**.
- These statistics were from the separate LC3-level testbench and do not establish all instructions were architecturally retired or that the final team `lc3_env` is validated. This extracted handoff was not independently re-simulated.

## Required dependencies and integration notes

1. `fetch_in_pkg`, `fetch_out_pkg`, `fetch_env_pkg` exist in the team's separate `stage/fetch` branch / PR #1. **Base the reference branch on `stage/fetch`** so these are available without duplicate copies.
2. The original bench also requires 8 instructor LC3 RTL files and 8 instructor `lc3_prediction_pkg` source files. Obtain them from authorized course materials and do not publish them as part of this reference. A UVMF example module `verilog_dut.v` is not part of those instructor files and is not required by the validated Makefile path.
3. The standalone `project_benches/imem_fetch_sandbox` contains its own UVMF bench structure. Do not replace the team's `project_benches/lc3`, `lc3_env`, or `regress.sh` with it. Reuse the responder, coverage collector, instruction sequences and tests as appropriate.
4. The sandbox uses a simplified data-memory interface (`Data_dout=0`, `complete_data=1`), not the final data-memory responder. The team must implement/integrate dmem and stage-level checking independently.
5. The instructor DUT/reference model use `instrmem_rd=0` when Fetch is disabled, while the written DesignSpec says high-impedance `Z`. This specification discrepancy remains unresolved.
6. The standalone `sim/Makefile` references omitted dependencies. The generated `sim/compile.do` is **not** a validated build entrypoint. There are **no runnable wrapper scripts in this reference ZIP**. Integrators must adjust compile order, bindings and test setup for the team's actual environment.

## Suggested reuse

Use `imem_pkg` as an active responder agent in the final `lc3_env` and connect the LC3 instruction request (`pc`, `instrmem_rd`) to its response (`Instr_dout`, `complete_instr`). Adapt the reference top-level sequence and instruction coverage to the team's final testbench. Recheck reset, branch, stall, response ordering, and scoreboard alignment in the combined system before claiming final coverage closure.
