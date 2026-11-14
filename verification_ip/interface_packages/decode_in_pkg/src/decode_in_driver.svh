class decode_in_driver extends uvm_driver #(decode_in_transaction);

    `uvm_component_utils(decode_in_driver)

    // declare driver bfm
    virtual decode_in_driver_bfm bfm;

    function new(
        string name = "decode_in_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // get virtual interface from config database
        // removed, config grabs virtual interface, and agent passes it down
    endfunction

    task run_phase(uvm_phase phase);
        bfm.wait_for_reset();
        forever begin
            // get item from sequencer port
            seq_item_port.get_next_item(req);

            // This calls the signal-level BFM task.
            bfm.drive(
                req.enable_decode,
                req.instruction,
                req.npc_in
            );

            // report item done to sequencer
            seq_item_port.item_done();
        end
    endtask

endclass