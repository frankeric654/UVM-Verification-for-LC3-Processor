class decode_out_monitor extends uvm_monitor;

    `uvm_component_utils(decode_out_monitor)

    // monitor bfm
    virtual decode_out_monitor_bfm bfm;
    // analysis port to send transactions to the coverage collector/scoreboard
    uvm_analysis_port #(decode_out_transaction) analysis_port;

    function new(
        string name = "decode_out_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);
        // construct the analysis port
        analysis_port = new("analysis_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        // declare transaction object
        decode_out_transaction trans;

        // wait until reset asserted - task from bfm
        bfm.wait_for_reset();

        forever begin
            // create transaction object
            trans = decode_out_transaction::type_id::create("trans");

            // call bfm monitor task
            bfm.monitor(
                .IR_o(trans.IR),
                .npc_out_o(trans.npc_out),
                .E_control_o(trans.E_control),
                .W_control_o(trans.W_control),
                .Mem_control_o(trans.Mem_control)
            );
            
            // send transaction on analysis port
            analysis_port.write(trans);
        end
    endtask

endclass