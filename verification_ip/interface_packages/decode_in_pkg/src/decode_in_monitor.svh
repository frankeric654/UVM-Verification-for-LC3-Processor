class decode_in_monitor extends uvm_monitor;
    `uvm_component_utils(decode_in_monitor)

    // decode_in_monitor_bfm is the BFM that will be used to monitor the DUT
    virtual decode_in_monitor_bfm bfm;
    // declare an analysis port to send transactions to the coverage collector
    uvm_analysis_port #(decode_in_transaction) analysis_port;

    function new(
        string name = "decode_in_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);
        // construct the analysis port
        analysis_port = new("analysis_port", this);
    endfunction


    task run_phase(uvm_phase phase);
        // declare transaction object
        decode_in_transaction trans;

        // wait until reset asserted - task from bfm
        bfm.wait_for_reset();

        forever begin
            // create transaction object
            trans = decode_in_transaction::type_id::create("trans");

            // call bfm monitor task
            bfm.monitor(
                .enable_decode_o(trans.enable_decode),
                .IMem_dout_o(trans.instruction),
                .npc_in_o(trans.npc_in)
            );
            
            // send transaction on analysis port
            analysis_port.write(trans);
        end
    endtask

endclass