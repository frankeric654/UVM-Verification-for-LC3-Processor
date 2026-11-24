interface control_in_monitor_bfm(control_in_if bus);
    timeunit 1ns;
    timeprecision 1ps;
    control_in_pkg::control_in_monitor monitor;
    bit monitoring = 0;
    longint unsigned cycle = 0;

    // Reset is synchronous. Capture the reset value seen by the DUT at the edge.

    // Clocking-block input skew avoids races with falling-edge stimulus.
    clocking sample_cb @(posedge bus.clock);
        default input #1step;
        input reset = bus.reset;
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
        cycle++;
        // The first pre-edge sample precedes synchronous reset.
        // Start functional checking after reset has taken effect.
        if (cycle == 1 && sample_cb.reset === 1'b1) begin
            $display("CONTROL_PRE_RESET: initial sample not compared");
            continue;
        end
        if (cycle != 0 && monitoring && monitor != null)
            monitor.notify_transaction(cycle, sample_cb.reset,
                sample_cb.complete_data, sample_cb.complete_instr, sample_cb.IR, sample_cb.IR_Exec, sample_cb.Instr_dout, sample_cb.NZP, sample_cb.psr);
    end
endinterface
