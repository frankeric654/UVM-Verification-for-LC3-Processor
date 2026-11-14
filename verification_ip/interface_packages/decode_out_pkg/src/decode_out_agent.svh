class decode_out_agent extends uvm_agent;
    // a passive agent
    `uvm_component_utils(decode_out_agent)
    decode_out_configuration configuration;
    uvm_sequencer #(decode_out_transaction) sequencer;
    decode_out_monitor monitor;
    decode_out_coverage coverage;

    // analysis port for scoreboard to connect to monitor
    uvm_analysis_port #(decode_out_transaction) monitor_ap;

    function new(string name = "decode_out_agent", uvm_component parent = null);
        super.new(name, parent);
        is_active = UVM_PASSIVE; // hardcoded passive until overwritten by configuration
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // pass configuration to the agent here
        if (!uvm_config_db#(decode_out_configuration)::get(
            this, "", "config", configuration
        )) begin
            `uvm_fatal("NOCONFIG", "Missing decode output configuration");
        end

        monitor = decode_out_monitor::type_id::create("monitor", this);
        // coverage
        if (configuration.coverage_enable) begin
            coverage = decode_out_coverage::type_id::create("coverage", this);
        end

        if (!uvm_config_db#(virtual decode_out_monitor_bfm)::get(
            this, "", "monitor_bfm", configuration.monitor_bfm
        )) begin
            `uvm_fatal("NOMONITORBFM", "Missing decode out monitor BFM")
        end

        // assign bfms to their actual "pointer"
        /*if (is_active == UVM_ACTIVE) begin
            driver.bfm = configuration.driver_bfm;
        end*/
        monitor.bfm = configuration.monitor_bfm;

        // create analysis port for monitor to connect to scoreboard
        monitor_ap = new("monitor_ap", this);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // connect sequencer to driver
        // driver.seq_item_port.connect(sequencer.seq_item_export);
        // connect coverage to driver analysis port if coverage is enabled
        if (coverage != null) begin
            monitor.analysis_port.connect(coverage.analysis_export);
        end
        // connect monitor analysis port to the agent analysis port for scoreboard
        monitor.analysis_port.connect(monitor_ap);
    endfunction


endclass :  decode_out_agent