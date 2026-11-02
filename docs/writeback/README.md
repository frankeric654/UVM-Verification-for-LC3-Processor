# Writeback verification: implementation guide

[繁體中文](README_zh-TW.md)

Owner: Cheng-Wei (clin39). Working branch: `stage/writeback`.

## Scope and current status

ECE 748 Project 3 builds an LC3 UVM/UVMF verification environment. The supplied
RTL already implements Writeback. This contribution will provide
`writeback_in_pkg`, `writeback_out_pkg`, and `writeback_env_pkg`.
Both agents are passive: they observe internal LC3 signals without driving them.
The predictor computes expected behavior; the scoreboard compares predictions
with observations. Final simulation runs at the complete LC3 level, as required
by assignment slides 7–9. Although the team splits work among five people, the
assignment requires six stage sub-environments, including Decode.

Only the initial input/output transfer types and this interface contract exist
so far. This is not yet a runnable UVM environment. No SystemVerilog compilation
or LC3 simulation has been performed for this contribution.

## Local layout

`ECE748/clin39_p3/` contains the supplied PDFs and RTL archive; `repo/` is the
GitHub checkout. The public contribution contains verification source and notes.

## Implementation sequence

1. Understand the WB signals and the two `*_types_pkg.sv` files.
2. Implement input/output interfaces and monitor BFMs; establish sampling timing.
3. Implement transactions, monitors, configuration, passive agents, and coverage.
4. Implement a stateful predictor tracking eight registers and PSR.
5. Implement a scoreboard with cycle alignment, unknown-value handling, and
   end-of-test checks for outstanding comparisons.
6. Connect analysis ports in the environment and integrate into the LC3 bench.
7. Run LC3-level tests and document bugs, coverage, and simulation evidence.

## Signal contract

Names follow the supplied `TopLevelLC3.v` instance `Writeback WB`. The final DUT
instance name is still to be agreed with the integration owner.

| WB port / transfer field | Width | LC3 wire | Purpose |
| --- | --- | --- | --- |
| clock | 1 | clock | Write clock; not part of the transfer payload |
| reset | 1 | reset | Reset observation for the predictor |
| enable_writeback | 1 | enable_writeback | Register write enable |
| W_Control | 2 | W_Control_out | Write-data selection |
| aluout | 16 | aluout | ALU result |
| memout | 16 | memout | Load data |
| pcout | 16 | pcout | LEA address result |
| npc | 16 | npc_out_dec | Retained RTL input; unused by selections 0/1/2 |
| sr1, sr2 | 3 each | sr1, sr2 | Register read addresses |
| dr | 3 | dr | Register write address |
| d1 | 16 | VSR1 | Asynchronous RegFile[sr1] read |
| d2 | 16 | VSR2 | Asynchronous RegFile[sr2] read |
| psr | 3 | psr | Negative, zero, and positive flags |

Transfer structs describe sampled data; they do not sample the DUT themselves.
Fields use four-state `logic` to preserve X/Z values for verification.

## Expected behavior

The design specification's WRITEBACK section and the supplied P2 writeback model
support the following write-data selections:

| W_Control | Write data |
| --- | --- |
| 2'b00 | aluout |
| 2'b01 | memout |
| 2'b10 | pcout |

Selection `2'b11` remains unresolved; do not assume it selects npc.
An enabled write updates RegFile[dr] and PSR according to the selected value:
negative = 100, zero = 010, positive = 001. Without a write, state should hold.
R0 is an ordinary writable register. Asynchronous reads must still be checked
when writeback is disabled.

## Timing and unknown values

- The specification permits initially unknown register contents. Track which
  registers have been initialized instead of assuming reset clears all entries.
  Initialize registers through instructions in the test program.
- Confirm precise WB reset behavior, including PSR and register retention, before
  implementing the predictor.
- Capture write enable, destination, selection, and data before the rising-edge
  NBA updates. Execute also updates at that edge; its new destination must not
  be paired with the previous write's data.
- Sample outputs after NBA and combinational settling, using the read addresses
  from that observation phase. Establish a shared cycle identification scheme;
  callback arrival order alone is insufficient.
- The supplied P2 writeback model has static register storage, two-state ports,
  and read-before-write ordering. It cannot be copied unchanged to predict
  post-edge asynchronous reads. Each predictor instance should own its state.

## Planned verification scenarios

Cover all three write sources; all eight destination and source registers;
negative/zero/positive and boundary values; disabled writes; simultaneous read
and write of the same register; consecutive overwrites; asynchronous read-address
changes; startup unknowns; and reset. Stimulus comes from the complete LC3
instruction/data memory responders, not from the passive WB agents.

## Integration dependencies

Agree on the UVMF version and generator conventions, top-level DUT instance name,
sampling/cycle convention, and ownership of LC3 integration and imem/dmem.

## Validation to date

The assignment, design specification, supplied RTL top-level port map, and P2
model were reviewed. Source types and documentation are the only implemented
artifacts; compilation, simulation, and coverage results are still pending.
