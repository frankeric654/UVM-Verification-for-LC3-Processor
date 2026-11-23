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
