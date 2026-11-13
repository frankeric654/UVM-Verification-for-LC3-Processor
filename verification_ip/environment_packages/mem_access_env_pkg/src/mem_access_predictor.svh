class mem_access_predictor extends uvm_subscriber #(mem_access_in_transaction);
    `uvm_component_utils(mem_access_predictor)

    uvm_analysis_port #(mem_access_out_transaction) predictor_ap;
    bit model_status;

    function new(
        string name = "mem_access_predictor",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        predictor_ap = new("predictor_ap", this);
    endfunction

    function void write(mem_access_in_transaction t);
        mem_access_out_transaction predicted_transaction;
        predicted_transaction =
            mem_access_out_transaction::type_id::create("predicted_transaction");

        model_status = mem_access_model(
            .M_Data(t.M_Data),
            .M_Addr(t.M_Addr),
            .M_Control(t.M_Control),
            .mem_state(t.mem_state),
            .DMem_dout(t.Data_dout),
            .DMem_addr(predicted_transaction.Data_addr),
            .DMem_din(predicted_transaction.Data_din),
            .memout(predicted_transaction.memout),
            .DMem_rd(predicted_transaction.Data_rd)
        );

        if (model_status) begin
            `uvm_error(
                "MEM_ACCESS_PREDICTOR",
                "mem_access_model reported a prediction failure"
            )
            return;
        end

        predictor_ap.write(predicted_transaction);
    endfunction
endclass : mem_access_predictor
