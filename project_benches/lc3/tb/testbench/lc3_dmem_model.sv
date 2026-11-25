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
  int unsigned wait_index[0:2];
  int unsigned pending_cycles = 0;
  logic response_pending = 0;
  logic delay_sweep = 0;
  int unsigned reads = 0, writes = 0;
  initial begin
    foreach (memory[i]) memory[i] = 0;
    foreach (wait_index[i]) wait_index[i] = 0;
    delay_sweep = $test$plusargs("LC3_DMEM_DELAY_SWEEP");
    if ($test$plusargs("LC3_DMEM_COVERAGE_INIT")) begin
      memory[0] = 16'h0000;
      memory[1] = 16'h0001;
      memory[2] = 16'h7FFF;
      memory[3] = 16'h8000;
      memory[4] = 16'hFFFF;
      memory[5] = 16'h5555;
      memory[6] = 16'hAAAA;
    end
  end

  always @(negedge clock) begin
    if (reset) begin
      complete <= 0;
      dout <= 0;
      response_pending <= 0;
      pending_cycles <= 0;
      foreach (wait_index[i]) wait_index[i] <= 0;
    end else if (complete) begin
      complete <= 0;
    end else if (response_pending) begin
      if (pending_cycles == 0) begin
        response_pending <= 0;
        complete <= 1;
      end else begin
        pending_cycles <= pending_cycles - 1;
      end
    end else if (mem_state inside {2'd0, 2'd1, 2'd2}) begin
      int unsigned response_delay;

      if ($isunknown({addr, rd}) || (!rd && $isunknown(din))) begin
        uvm_pkg::uvm_report_error(
          "DMEM_REQUEST", "Unknown address/read control or write data");
      end else begin
        if (rd) begin
          dout <= memory[addr];
          reads++;
        end else begin
          memory[addr] <= din;
          writes++;
        end

        response_delay = 0;
        if (delay_sweep) begin
          case (wait_index[mem_state] % 6)
            0: response_delay = 0;
            1: response_delay = 1;
            2: response_delay = 2;
            3: response_delay = 3;
            4: response_delay = 6;
            5: response_delay = 10;
          endcase
          wait_index[mem_state]++;
        end

        if (response_delay == 0) begin
          complete <= 1;
        end else begin
          response_pending <= 1;
          pending_cycles <= response_delay - 1;
        end
      end
    end
  end
  final $display("LC3_DMEM reads=%0d writes=%0d", reads, writes);
endmodule
