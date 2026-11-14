class mem_access_env_configuration extends uvm_object;
    `uvm_object_utils(mem_access_env_configuration)

    mem_access_in_configuration config_in;
    mem_access_out_configuration config_out;

    function new(string name = "mem_access_env_configuration");
        super.new(name);
        config_in = mem_access_in_configuration::type_id::create("config_in");
        config_out = mem_access_out_configuration::type_id::create("config_out");
    endfunction

    function void initialize(
        string parent_path,
        string input_interface_name,
        uvm_active_passive_enum input_activity,
        string output_interface_name,
        uvm_active_passive_enum output_activity
    );
        config_in.initialize(parent_path, input_interface_name, input_activity);
        config_out.initialize(parent_path, output_interface_name, output_activity);
    endfunction
endclass
