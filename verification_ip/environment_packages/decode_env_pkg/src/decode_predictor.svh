class decode_predictor extends uvm_subscriber #(decode_in_transaction);

    `uvm_component_utils(decode_predictor)

    uvm_analysis_port #(decode_out_transaction) predictor_ap;
    bit model_status;
    decode_out_transaction  previous_output_transaction;
    

    function new(string name = "decode_predictor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // built in analysis export
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        predictor_ap = new("predictor_ap", this);
        previous_output_transaction = decode_out_transaction::type_id::create("previous_output_transaction");
        previous_output_transaction.IR = '0;
        previous_output_transaction.npc_out = '0;
        previous_output_transaction.E_control = '0;
        previous_output_transaction.W_control = '0;
        previous_output_transaction.Mem_control = '0;

        
    endfunction

    function void write(decode_in_transaction t);
        decode_out_transaction predicted_transaction;
        predicted_transaction = decode_out_transaction::type_id::create("predicted_transaction");

        if(t.enable_decode) begin
            model_status = decode_model(
                .instr_dout(t.instruction),
                .npc_in(t.npc_in),
                .ir(predicted_transaction.IR),
                .npc_out(predicted_transaction.npc_out),
                .e_control(predicted_transaction.E_control),
                .w_control(predicted_transaction.W_control),
                .mem_control(predicted_transaction.Mem_control)
            );

            if (model_status) begin
                `uvm_error("DECODE_PREDICTOR",
                        "decode_model reported a prediction failure")
                return;
            end
            
            previous_output_transaction.copy(predicted_transaction);
        end
        else begin
            predicted_transaction.copy(previous_output_transaction);
        end

        predictor_ap.write(predicted_transaction);
    endfunction

endclass : decode_predictor