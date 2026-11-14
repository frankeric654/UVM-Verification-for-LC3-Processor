interface control_in_monitor_bfm(control_in_if bus);
    timeunit 1ns;
    timeprecision 1ps;
    control_in_pkg::control_in_monitor monitor;
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
        input complete_data = bus.complete_data;
        input complete_instr = bus.complete_instr;
        input IR = bus.IR;
        input IR_Exec = bus.IR_Exec;
        input Instr_dout = bus.Instr_dout;
        input NZP = bus.NZP;
        input psr = bus.psr;
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
                sample_cb.complete_data, sample_cb.complete_instr, sample_cb.IR, sample_cb.IR_Exec, sample_cb.Instr_dout, sample_cb.NZP, sample_cb.psr);
    end
endinterface
