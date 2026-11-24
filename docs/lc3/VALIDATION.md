# LC3 integration validation - November 24, 2026

Validated candidate: `5fa986e`.

Tools: Questa 2025.1_1, UVM 1.2, UVMF 2023.4_2.
Platform: NCSU Grendel.

## Current results

- Custom instruction coverage: 37960/37960.
- Merged Fetch behavior coverage: 24/24.
- Control branch-condition coverage: 24/24.
- MemAccess transition coverage: 11/11.
- Exhaustive Fetch scoreboard: 99895 matches, 0 mismatches.
- IMEM protocol errors: 0.
- All six stage scoreboards active.
- Simulator errors: 0.
- Simulator warnings: 118 per test.

Strict regression in the delivery infrastructure experiment
reported 13 Control errors in exhaustive and 4 in directed.
Both tests completed and produced merged coverage.

Characterization with experimental NOP handling enabled
reported only the four known Control reset mismatches per test.

The instruction stream digest remained 605597dd45b36595.

These results are not final verification sign-off.

## Validated changes

- a731498: corrected MemAccess transition bins.
- eec1287: independent Fetch timing audit.
- 0c89539: regression artifact collection on functional failure,
  coverage summary and external coverage binding.
- 5fa986e: reject X/Z instruction read controls.

The external bind probe achieved 2/2 coverage bins.
Independent X and Z injections were detected by both monitors.
Normal regression retained the previous functional results.

The actual instructor-bound coverage model remains externally
evaluated.

## Runtime history

| Experiment | Wall time |
| --- | ---: |
| Original unified infrastructure | 55.160 s |
| MemAccess transition correction | 59.093 s |
| Fetch contract audit | 58.123 s |
| Strict delivery regression with bind | 59.464 s |
| Delivery characterization | 55.595 s |
| Fetch read-control correction | 66.495 s |

These are individual measurements on a shared server,
not controlled performance comparisons.

## Remaining integration blockers

- Control reset and zero-word NOP specification decisions.
- Formal DMEM responder agent and sequence.
- Final top-level environment and sequence integration.
- Course RTL directory placement.
- Strict regression after final integration.
- Instructor-bound coverage evaluation.

MemAccess transition conflicts have been resolved.
MemAccess state-path coverage remains with its stage owner.

The instructor canceled the separate test-plan requirement
during the October 16 lecture. The submission requires a
coverage summary rather than a detailed coverage report.

See [README.md](README.md) for current build instructions.

---

## Historical infrastructure validation

The following is retained as an earlier validation snapshot.

# LC3 integration validation — November 24, 2026

Validated infrastructure commit: `ce0b32c`.

Environment: Questa 2025.1_1, UVM 1.2, UVMF 2023.4_2.
Validation performed on NCSU Grendel.

## Current characterization results

- Compilation: 0 errors, 0 warnings.
- Custom IMEM instruction coverage: 37960/37960.
- Fetch behavior coverage: 24/24 merged bins.
- Exhaustive Fetch scoreboard: 99895 matches, 0 mismatches.
- IMEM protocol errors: 0.
- All six scoreboards active.
- Non-reset mismatches: 0 with experimental Control NOP mode.
- Four known Control reset mismatches per test remain.
- Simulator errors: 0.
- Simulation warnings: 123 per full-regression test.
- Total wall-clock regression time: 55.160 seconds.

These are characterization results, not final verification sign-off.

## Build and regression commands

From project_benches/lc3/sim, with QUESTA_HOME and
UVMF_HOME configured:

| Command | Purpose |
| --- | --- |
| make compile | Compile all sources |
| make smoke | Strict single-seed smoke |
| make smoke-regress | Strict multi-seed smoke |
| make baseline | Known-issue baseline check |
| make regress | Strict full regression |
| make characterize | Experimental full regression |
| ./regress.sh | Strict reproducible regression |
| ./regress.sh --characterize | Characterization run |
| python3 test_sim_checks.py -v | Transcript checker tests |

The standalone regress.sh exit statuses are:

- 0: strict regression passed.
- 1: regression failure.
- 2: characterization completed; not final sign-off.

GNU Make reports nonzero recipe exit statuses as errors.
The completion marker and detailed results must also be checked.

The regression preserves transcripts, individual UCDB files,
merged.ucdb, coverage_details.txt and timing results.

## Remaining integration blockers

- Resolve Control reset and zero-word NOP semantics.
- Resolve MemAccess coverage transition-bin conflicts.
- Integrate the required DMEM UVM responder.
- Revalidate coverage against the agreed course testplan.
- Perform strict regression after team integration.

---

## Historical validation record

# Integration validation — November 22, 2026

Base: team main `4ff9e1245e02f80313bc7577890f627e1bc79e69`.
Tools: Questa 2024.2, matching UVM 1.2 headers/library, local UVMF_2023.3,
and the user's unmodified encrypted course LC3 RTL.

## Result

- Full compile of both tops, all six stage packages, UVMF base and IMem: **0 errors, 0 warnings**.
- Elaboration and 300-clock simulation, seed 1: reached the test completion marker at 3057 ns.
- All six comparison paths had activity; no missing BFM/configuration fatal.
- Simulator warnings about virtual interfaces with interface ports remain visible.
- UVM report: **522 errors, 0 fatals**. **Overall smoke result: FAIL**.
- Runner returned exit 1 despite the simulator process returning 0. No stage checker was disabled or demoted.

| Stage | Observed result |
| --- | --- |
| Fetch | 301 predictions/comparisons; 85 matches, 216 mismatches |
| Decode | 301 comparisons, 0 mismatches, 0 expected entries remaining |
| Execute | 306 expected/actual; 303 matches, 2 mismatches, 1 skipped; 0 entries remaining |
| MemAccess | 301 comparisons, 176 mismatches, 0 expected entries remaining |
| Writeback | 306 pairs, 883 field checks, 0 mismatches, 9 unchecked pairs |
| Control | 305 comparisons; 177 matches, 128 mismatches; 0 pending |

IMem observed 79 responses; the integration dmem model serviced 93 reads and
22 writes. WB's unchecked pairs and Execute's skipped transaction are reported
by their existing checkers, not counted as successful checks here. This short
run is not evidence of instruction retirement, complete functional coverage,
or correctness of every memory transaction.

## Reproduce

From the repository root with the university license environment loaded:

```bash
module load questa/2024.2
python project_benches/lc3/sim/run.py \
  --rtl-dir /path/to/LC3_veloce_encrypted \
  --uvmf-home /path/to/UVMF_2023.3 \
  --questa-home /path/to/questasim \
  --out /tmp/lc3-integration-run \
  --seed 1 --cycles 300
```

Inspect `compile.log` and `simulation.log` in the output directory. The original
local evidence for this handoff is `/tmp/clin39_lc3_integration_final/` on the
validation machine (temporary, not a portable/shared location). Compilation
libraries, licensed UVMF source and instructor RTL are not committed.

## Open findings for stage owners

These are observations and initial diagnoses, not all confirmed DUT bugs.

- **MemAccess:** at 55 ns, expected idle outputs are address/data 0000 and read=0,
  while DUT outputs are Z. The supplied model declares `bit` output arguments,
  which cannot preserve its assigned Z values. The existing predictor passes
  those results directly to a four-state comparison. This accounts for the
  first idle mismatch and warrants a specification-aware predictor adapter;
  do not force the DUT Z pins to zero to pass the test.
- **Control:** during reset the default model configuration expects enable_fetch=0,
  while this supplied DUT drives 1. The existing configuration already notes
  this discrepancy. Reset accounts for 5 failures; the other 123 comparison
  failures still need investigation. The integration retains the default
  reference setting rather than silently selecting the DUT's behavior.
- **Execute:** at 95 and 105 ns the compared samples differ in M_Data: predicted
  0, actual X. Startup/undefined-field validity needs review before calling
  this a DUT bug. The integration does not coerce X to 0.
- **Fetch:** 216 PC/npc mismatches arise in the combined run containing memory
  and control instructions. Predictor cycle alignment, branch targets and
  pipeline stalls require investigation. No root cause has been established.

Decode and WB have zero mismatches in this run only; this is not exhaustive
validation. The final project also needs the formal dmem UVM agent, broader
sequences/regression, coverage collection/merge and the required reports.
