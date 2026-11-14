class control_predictor extends uvm_subscriber #(control_in_transaction);
    `uvm_component_utils(control_predictor)
    uvm_analysis_port #(control_out_transaction) analysis_port;
    control_reference_model model;
    bit reset_enable_fetch = 0;

    function new(string name = "control_predictor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
        model = control_reference_model::type_id::create("model");
    endfunction

    virtual function void write(control_in_transaction t);
        control_out_transaction predicted = model.predict(t, reset_enable_fetch);
        analysis_port.write(predicted);
    endfunction
endclass
