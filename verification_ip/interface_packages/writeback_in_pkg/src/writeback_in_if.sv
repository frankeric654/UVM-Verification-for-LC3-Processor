// Passive view of the Writeback inputs. The LC3 bench connects these ports.
interface writeback_in_if (
  input wire        clock,
  input wire        reset,
  input wire        enable_writeback,
  input wire [1:0]  W_Control,
  input wire [15:0] aluout,
  input wire [15:0] memout,
  input wire [15:0] pcout,
  input wire [15:0] npc,
  input wire [2:0]  sr1,
  input wire [2:0]  sr2,
  input wire [2:0]  dr
);
endinterface
