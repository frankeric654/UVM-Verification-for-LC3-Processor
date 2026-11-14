class control_env_configuration extends uvm_object;
    `uvm_object_utils(control_env_configuration)
    control_in_configuration control_in_config;
    control_out_configuration control_out_config;
    // DesignSpec p27 prose says zero; its waveform and supplied RTL show one.
    bit reset_enable_fetch = 0;

    function new(string name = "control_env_configuration");
        super.new(name);
        control_in_config = control_in_configuration::type_id::create("control_in_config");
        control_out_config = control_out_configuration::type_id::create("control_out_config");
    endfunction

    function void initialize(string environment_path,
                             string input_interface_name = "control_in",
                             string output_interface_name = "control_out");
        control_in_config.initialize({environment_path, ".control_in_agent"}, input_interface_name);
        control_out_config.initialize({environment_path, ".control_out_agent"}, output_interface_name);
        uvm_config_db#(control_env_configuration)::set(null, environment_path, "configuration", this);
    endfunction
endclass
