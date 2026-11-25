class decode_in_coverage extends uvm_subscriber #(decode_in_transaction);

    `uvm_component_utils(decode_in_coverage)
    decode_in_transaction coverage_trans;

    localparam logic [3:0] OP_ADD = 4'b0001;
    localparam logic [3:0] OP_AND = 4'b0101;
    localparam logic [3:0] OP_NOT = 4'b1001;
    localparam logic [3:0] OP_LEA = 4'b1110;
    localparam logic [3:0] OP_LD  = 4'b0010;
    localparam logic [3:0] OP_LDR = 4'b0110;
    localparam logic [3:0] OP_LDI = 4'b1010;
    localparam logic [3:0] OP_ST  = 4'b0011;
    localparam logic [3:0] OP_STR = 4'b0111;
    localparam logic [3:0] OP_STI = 4'b1011;
    localparam logic [3:0] OP_BR  = 4'b0000;
    localparam logic [3:0] OP_JMP = 4'b1100;

    // covergroup for coverage of ISA
    covergroup cg_decode_in_ISA;
        option.per_instance = 1;
        option.auto_bin_max = 512;

        opcode_cp : coverpoint coverage_trans.instruction[15:12] {
            // Cover the valid opcodes and flag all other opcodes as illegal.
            bins opcode_bins[12] = {OP_ADD, OP_AND, OP_NOT, OP_LEA, OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI, OP_BR, OP_JMP};
            illegal_bins invalid_opcodes = default;
        }

        enable_decode_cp : coverpoint coverage_trans.enable_decode {
            bins disabled = {1'b0};
            bins enabled = {1'b1};
        }

        npc_cp : coverpoint coverage_trans.npc_in {
            bins zero = {16'h0000};
            bins instruction_memory_start = {16'h3000};
            bins low_address = {[16'h0001:16'h2FFF]};
            bins normal_address = {[16'h3001:16'h7FFF]};
            bins high_address = {[16'h8000:16'hFFFE]};
            bins maximum = {16'hFFFF};
        }

        addand_mode : coverpoint coverage_trans.instruction[5]
                      iff (coverage_trans.instruction[15:12] inside {OP_ADD, OP_AND}) {
            bins register_mode = {1'b0};
            bins immediate_mode = {1'b1};
        }
        dr_cp : coverpoint coverage_trans.instruction[11:9]
                iff (coverage_trans.instruction[15:12] inside {OP_ADD, OP_AND, OP_NOT, OP_LEA, OP_LD, OP_LDR, OP_LDI});
        sr_cp : coverpoint coverage_trans.instruction[11:9]
                iff (coverage_trans.instruction[15:12] inside {OP_ST, OP_STR, OP_STI});
        sr1_cp : coverpoint coverage_trans.instruction[8:6]
                 iff (coverage_trans.instruction[15:12] inside {OP_ADD, OP_AND, OP_NOT, OP_LDR, OP_STR});
        sr2_cp : coverpoint coverage_trans.instruction[2:0]
                 iff ((coverage_trans.instruction[15:12] inside {OP_ADD, OP_AND}) && !coverage_trans.instruction[5]);
        imm5_cp : coverpoint coverage_trans.instruction[4:0]
                  iff ((coverage_trans.instruction[15:12] inside {OP_ADD, OP_AND}) && coverage_trans.instruction[5]) {
            bins negative = {[5'b10000:5'b11111]};
            bins zero = {5'b00000};
            bins positive = {[5'b00001:5'b01111]};
        }
        pc_offset9_cp : coverpoint coverage_trans.instruction[8:0]
                        iff (coverage_trans.instruction[15:12] inside {OP_LD, OP_ST, OP_LDI, OP_STI, OP_LEA, OP_BR}) {
            bins min_offset = {9'h100};
            bins negative_16_255 = {[9'h101:9'h1EF]};
            bins negative_2_15 = {[9'h1F0:9'h1FE]};
            bins negative_one = {9'h1FF};
            bins zero = {9'b0};
            bins positive_one = {9'h001};
            bins positive_2_15 = {[9'h002:9'h00F]};
            bins positive_16_254 = {[9'h010:9'h0FE]};
            bins max_offset = {9'h0FF};
        }
        offset6_cp : coverpoint coverage_trans.instruction[5:0]
                     iff (coverage_trans.instruction[15:12] inside {OP_LDR, OP_STR}) {
            bins min_offset = {6'h20};
            bins negative_2_31 = {[6'h21:6'h3E]};
            bins negative_one = {6'h3F};
            bins zero = {6'b000000};
            bins positive_one = {6'h01};
            bins positive_2_30 = {[6'h02:6'h1E]};
            bins max_offset = {6'h1F};
        }
        base_register_cp : coverpoint coverage_trans.instruction[8:6]
                           iff (coverage_trans.instruction[15:12] inside {OP_LDR, OP_STR, OP_JMP});
        br_nzp_cp : coverpoint coverage_trans.instruction[11:9]
                    iff (coverage_trans.instruction[15:12] == OP_BR) {
            bins never_taken = {3'b000};
            bins br_negative = {3'b100};
            bins br_zero = {3'b010};
            bins br_positive = {3'b001};
            bins br_combinations[] = {[3'b011:3'b111]};
        }
        not_fixed_cp : coverpoint coverage_trans.instruction[5:0]
                       iff (coverage_trans.instruction[15:12] == OP_NOT) {
            bins legal_encoding = {6'h3F};
            illegal_bins illegal_encoding = {[6'h00:6'h3E]};
        }
        jmp_fixed_cp : coverpoint {coverage_trans.instruction[11:9], coverage_trans.instruction[5:0]}
                       iff (coverage_trans.instruction[15:12] == OP_JMP) {
            bins legal_encoding = {9'h000};
            illegal_bins illegal_encoding = {[9'h001:9'h1FF]};
        }

        // Exercise the instruction-specific operand field combinations.
        alu_register_x : cross dr_cp, sr1_cp, sr2_cp
                         iff ((coverage_trans.instruction[15:12] inside {OP_ADD, OP_AND}) && !coverage_trans.instruction[5]);
        alu_immediate_x : cross dr_cp, sr1_cp, imm5_cp
                          iff ((coverage_trans.instruction[15:12] inside {OP_ADD, OP_AND}) && coverage_trans.instruction[5]);
        not_x : cross dr_cp, sr1_cp iff (coverage_trans.instruction[15:12] == OP_NOT);
        pc_relative_load_store_x : cross dr_cp, sr_cp, pc_offset9_cp
                                   iff (coverage_trans.instruction[15:12] inside {OP_LD, OP_ST, OP_LDI, OP_STI, OP_LEA});
        base_relative_x : cross dr_cp, sr_cp, base_register_cp, offset6_cp
                          iff (coverage_trans.instruction[15:12] inside {OP_LDR, OP_STR});
        branch_x : cross br_nzp_cp, pc_offset9_cp iff (coverage_trans.instruction[15:12] == OP_BR);
        jump_x : cross opcode_cp, base_register_cp iff (coverage_trans.instruction[15:12] == OP_JMP);
        enable_opcode_x : cross enable_decode_cp, opcode_cp;
    endgroup : cg_decode_in_ISA
    
    function new(string name = "decode_in_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_decode_in_ISA = new();
    endfunction : new
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase
    
    // function void sample(decode_in_transaction trans);
    //     cg_decode_in_ISA.sample();
    // endfunction : sample
    
    virtual function void write(decode_in_transaction t);
        `uvm_info("COV", "Received transaction", UVM_HIGH);
        coverage_trans = t;
        cg_decode_in_ISA.sample();
    endfunction : write

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("DECODE_IN_COV",
            $sformatf("Decode input functional coverage=%0.2f%%",
                      cg_decode_in_ISA.get_inst_coverage()),
            UVM_LOW)
    endfunction : report_phase
    
endclass : decode_in_coverage