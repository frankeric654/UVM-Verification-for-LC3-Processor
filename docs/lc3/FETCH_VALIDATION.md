# Fetch integration validation

Validated base: a731498
Date: November 24, 2026
Tools: Questa 2025.1_1, UVM 1.2, UVMF 2023.4_2.

## Results

| Metric | Exhaustive | Directed |
| --- | ---: | ---: |
| Fetch matches | 99895 | 301 |
| Fetch mismatches | 0 | 0 |
| Reset PC checks | 5 | 5 |
| Reset release | 1 | 1 |
| PC hold | 59876 | 9 |
| PC increment | 37990 | 287 |
| Branch redirect | 2028 | 4 |
| PC wraparound | 7 | 1 |
| NPC checks | 99895 | 301 |
| IMEM requests | 37992 | 289 |
| Observed responses | 37991 | 288 |
| PC update resume | 23667 | 5 |

Merged Fetch behavior coverage: 24/24 bins.
Custom instruction coverage: 37960/37960.
Simulator errors: 0.
Known Control reset mismatches: 4 per test.
Simulator warnings: 118 per test.

## Reproduction

The accompanying fetch_contract_audit.svh contains the
independent audit instrumentation used in the experiment.

Insert its contents immediately before endmodule in
hdl_top.sv in an isolated checkout of the validated base,
then execute regress.sh --characterize.

The audit is not included in the production regression.

## Qualification

These results validate the current fixed-latency IMEM
configuration, not arbitrary response latency.

One final response remained unobserved in each test.
Taken redirects were exercised; explicit not-taken branch
coverage requires separate confirmation.

The four Control reset discrepancies and experimental
zero-word NOP behavior remain subject to review.

Final DMEM integration and instructor-bound instruction
coverage have not yet been qualified.

This is characterization evidence, not final sign-off.

## Subsequent read-control qualification

Commit 5fa986e implements the instructor clarification that
inactive instrmem_rd must be 0, not Z.

Both Fetch and IMEM monitors reject X and Z before conversion.

Independent X and Z fault injections were detected by both
monitors at 105 ns.

Normal exhaustive and directed characterization retained
37960/37960 instruction coverage, 24/24 Fetch behavior bins
and the original instruction-stream digest.

Only the four known Control reset mismatches remained per test.
