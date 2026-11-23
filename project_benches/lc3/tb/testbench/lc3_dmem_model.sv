// Integration memory model, NOT a replacement for the required dmem UVM agent.
// One clock-wide completion pulses, separated by an idle response cycle.
// Retain read data between responses: indirect addressing consumes that pointer.
module lc3_dmem_model(
  input logic clock, reset,
  input logic [1:0] mem_state,
  input logic [15:0] addr, din,
  input logic rd,
  output logic [15:0] dout = 0,
  output logic complete = 0
);
  timeunit 1ns; timeprecision 1ps;
  logic [15:0] memory[0:65535];
  int unsigned reads = 0, writes = 0;
  initial foreach (memory[i]) memory[i] = 0;
  always @(negedge clock) begin
    if (reset) begin
      complete <= 0;
      dout <= 0;
    end else if (complete) begin
      complete <= 0;
    end else if (mem_state inside {2'd0, 2'd1, 2'd2}) begin
      if ($isunknown({addr, rd})) begin
        uvm_pkg::uvm_report_error("DMEM_REQUEST", "Unknown address/read control");
      end else if (rd) begin
        dout <= memory[addr];
        reads++;
        complete <= 1;
      end else begin
        memory[addr] <= din;
        writes++;
        complete <= 1;
      end
    end
  end
  final $display("LC3_DMEM reads=%0d writes=%0d", reads, writes);
endmodule
