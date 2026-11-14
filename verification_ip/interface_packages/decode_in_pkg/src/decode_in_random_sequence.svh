class decode_in_random_sequence extends uvm_sequence #(decode_in_transaction);

    `uvm_object_utils(decode_in_random_sequence)

    decode_in_transaction req;

    function new(string name = "decode_in_random_sequence");
        super.new(name);
    endfunction

    task body();
        repeat (50) begin
            req = decode_in_transaction::type_id::create("req");

            start_item(req);
            if (!req.randomize()) begin
                `uvm_fatal("SEQ", "Transaction randomization failed")
            end
            finish_item(req);
        end
    endtask

endclass