interface control_out_monitor_bfm(control_out_if bus);
    timeunit 1ns;
    timeprecision 1ps;
    control_out_pkg::control_out_monitor monitor;
    bit monitoring = 0;
    logic reset_at_edge;
    longint unsigned cycle = 0;

    // Reset is synchronous. Capture the reset value seen by the DUT at the edge.
    always @(posedge bus.clock) begin
        reset_at_edge = bus.reset;
        cycle++;
    end

    // Clocking-block input skew avoids races with falling-edge stimulus.
    clocking sample_cb @(negedge bus.clock);
        default input #1step;
        input enable_updatePC = bus.enable_updatePC;
        input enable_fetch = bus.enable_fetch;
        input enable_decode = bus.enable_decode;
        input enable_execute = bus.enable_execute;
        input enable_writeback = bus.enable_writeback;
        input bypass_alu_1 = bus.bypass_alu_1;
        input bypass_alu_2 = bus.bypass_alu_2;
        input bypass_mem_1 = bus.bypass_mem_1;
        input bypass_mem_2 = bus.bypass_mem_2;
        input mem_state = bus.mem_state;
        input br_taken = bus.br_taken;
    endclocking

    task start_monitoring(); monitoring = 1; endtask
    task wait_for_reset();
        wait (bus.reset === 1'b1);
        @(negedge bus.reset);
    endtask
    task wait_for_num_clocks(int unsigned count);
        repeat (count) @(posedge bus.clock);
    endtask

    initial forever begin
        @(sample_cb);
        if (cycle != 0 && monitoring && monitor != null)
            monitor.notify_transaction(cycle, reset_at_edge,
                sample_cb.enable_updatePC, sample_cb.enable_fetch, sample_cb.enable_decode, sample_cb.enable_execute, sample_cb.enable_writeback, sample_cb.bypass_alu_1, sample_cb.bypass_alu_2, sample_cb.bypass_mem_1, sample_cb.bypass_mem_2, sample_cb.mem_state, sample_cb.br_taken);
    end
endinterface
