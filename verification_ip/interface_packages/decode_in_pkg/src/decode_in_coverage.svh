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

        opcode_cp : coverpoint coverage_trans.instruction[15:12] {
            // Cover the valid opcodes and flag all other opcodes as illegal.
            bins opcode_bins[12] = {OP_ADD, OP_AND, OP_NOT, OP_LEA, OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI, OP_BR, OP_JMP};
            illegal_bins invalid_opcodes = default;
        }
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
    
endclass : decode_in_coverage