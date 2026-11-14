class mem_access_out_agent extends uvm_agent;
    `uvm_component_utils(mem_access_out_agent)

    mem_access_out_configuration configuration;
    mem_access_out_monitor monitor;
    mem_access_out_coverage coverage;
    uvm_analysis_port #(mem_access_out_transaction) monitor_ap;

    function new(string name = "mem_access_out_agent", uvm_component parent = null);
        super.new(name, parent);
        is_active = UVM_PASSIVE;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(mem_access_out_configuration)::get(
                this, "", "config", configuration
            )) begin
            `uvm_fatal("NOCONFIG", "Missing mem access output configuration")
        end
        monitor = mem_access_out_monitor::type_id::create("monitor", this);
        if (configuration.coverage_enable) begin
            coverage = mem_access_out_coverage::type_id::create("coverage", this);
        end
        if (!uvm_config_db#(virtual mem_access_out_monitor_bfm)::get(
                this, "", "monitor_bfm", configuration.monitor_bfm
            )) begin
            `uvm_fatal("NOMONITORBFM", "Missing mem access output monitor BFM")
        end
        monitor.bfm = configuration.monitor_bfm;
        monitor_ap = new("monitor_ap", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (coverage != null) begin
            monitor.analysis_port.connect(coverage.analysis_export);
        end
        monitor.analysis_port.connect(monitor_ap);
    endfunction
endclass : mem_access_out_agent
