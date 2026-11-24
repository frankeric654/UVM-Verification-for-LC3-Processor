class decode_out_coverage extends uvm_subscriber #(decode_out_transaction);

    `uvm_component_utils(decode_out_coverage)
    decode_out_transaction coverage_trans;

    covergroup cg_decode_out;
        option.per_instance = 1;
        option.auto_bin_max = 512;

        ir_opcode_cp : coverpoint coverage_trans.IR[15:12] {
            bins br = {4'b0000};
            bins add = {4'b0001};
            bins ld = {4'b0010};
            bins st = {4'b0011};
            bins and_op = {4'b0101};
            bins ldr = {4'b0110};
            bins str = {4'b0111};
            bins not_op = {4'b1001};
            bins ldi = {4'b1010};
            bins sti = {4'b1011};
            bins jmp = {4'b1100};
            bins lea = {4'b1110};
            illegal_bins unsupported = default;
        }

        w_control_cp : coverpoint coverage_trans.W_control {
            bins alu_result = {2'b00};
            bins memory_result = {2'b01};
            bins effective_address = {2'b10};
            illegal_bins reserved = {2'b11};
        }

        mem_control_cp : coverpoint coverage_trans.Mem_control {
            bins direct_memory = {1'b0};
            bins indirect_memory = {1'b1};
        }

        npc_out_cp : coverpoint coverage_trans.npc_out {
            bins zero = {16'h0000};
            bins instruction_memory = {[16'h3000:16'h30FF]};
            bins low = {[16'h0001:16'h2FFF]};
            bins high = {[16'h3100:16'hFFFF]};
        }

        alu_control_cp : coverpoint coverage_trans.E_control[5:4] {
            bins add = {2'b00};
            bins and_op = {2'b01};
            bins not_op = {2'b10};
        }
        pcselect1_cp : coverpoint coverage_trans.E_control[3:2];
        op2select_cp : coverpoint coverage_trans.E_control[0];

        opcode_writeback_x : cross ir_opcode_cp, w_control_cp;
        opcode_memory_x : cross ir_opcode_cp, mem_control_cp;
        writeback_execute_x : cross w_control_cp, alu_control_cp;
    endgroup

    function new(string name = "decode_out_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_decode_out = new();
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase
    
    virtual function void write(decode_out_transaction t);
        `uvm_info("COV", "Received transaction", UVM_HIGH);
        coverage_trans = t;
        cg_decode_out.sample();
    endfunction : write

endclass : decode_out_coverage