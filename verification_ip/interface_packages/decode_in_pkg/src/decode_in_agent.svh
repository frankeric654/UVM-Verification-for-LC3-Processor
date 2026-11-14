class decode_in_agent extends uvm_agent;

    `uvm_component_utils(decode_in_agent)

    decode_in_configuration configuration;
    uvm_sequencer #(decode_in_transaction) sequencer;
    decode_in_driver driver;
    decode_in_monitor monitor;
    decode_in_coverage coverage;
    uvm_analysis_port #(decode_in_transaction) monitor_ap;

    

    function new(string name = "decode_in_agent", uvm_component parent = null);
        super.new(name, parent);
        // agent hard-coded to be active
        is_active = UVM_ACTIVE;
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // pass configuration to the agent
        if (!uvm_config_db#(decode_in_configuration)::get(
                this, "", "config", configuration
            )) begin
            `uvm_fatal("NOCONFIG", "Missing decode input configuration")
        end

        sequencer = uvm_sequencer#(decode_in_transaction)::type_id::create(
            "sequencer", this
        );
        driver = decode_in_driver::type_id::create("driver", this);
        monitor = decode_in_monitor::type_id::create("monitor", this);
        if (configuration.coverage_enable) begin
            coverage = decode_in_coverage::type_id::create("coverage", this);
        end

        driver.bfm = configuration.driver_bfm;
        monitor.bfm = configuration.monitor_bfm;

        monitor_ap = new("monitor_ap", this);
        
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // connect sequencer to driver
        driver.seq_item_port.connect(sequencer.seq_item_export);
        // connect coverage to driver analysis port if coverage is enabled
        if (coverage != null) begin
            monitor.analysis_port.connect(coverage.analysis_export);
        end

        monitor.analysis_port.connect(monitor_ap);
    endfunction
endclass : decode_in_agent