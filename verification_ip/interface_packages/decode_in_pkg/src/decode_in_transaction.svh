class decode_in_transaction extends uvm_sequence_item;
    
    `uvm_object_utils(decode_in_transaction)

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
    

    rand bit [15:0] instruction;
    rand bit [15:0] npc_in;
    rand bit        enable_decode;

    constraint valid_opcode_c {
        instruction[15:12] inside {
            //4'h1, 4'h5, 4'h9, 4'hE // ADD, AND, NOT, LEA
            OP_ADD, OP_AND, OP_NOT, OP_LEA, OP_LD, OP_LDR, OP_LDI, OP_ST, OP_STR, OP_STI, OP_BR, OP_JMP
        };
    }

    function new (string name = "decode_in_transaction");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("instruction: %h, npc_in: %h, enable_decode: %b", 
            instruction, npc_in, enable_decode
        );
    endfunction
endclass
