//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// PACKAGE: This file defines all of the files contained in the
//    interface package that will run on the host simulator.
//
// CONTAINS:
//    - <imem_typedefs_hdl>
//    - <imem_typedefs.svh>
//    - <imem_transaction.svh>

//    - <imem_configuration.svh>
//    - <imem_driver.svh>
//    - <imem_monitor.svh>

//    - <imem_transaction_coverage.svh>
//    - <imem_sequence_base.svh>
//    - <imem_random_sequence.svh>

//    - <imem_responder_sequence.svh>
//    - <imem2reg_adapter.svh>
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
package imem_pkg;
  
   import uvm_pkg::*;
   import uvmf_base_pkg_hdl::*;
   import uvmf_base_pkg::*;
   import imem_pkg_hdl::*;

   `include "uvm_macros.svh"

   // pragma uvmf custom package_imports_additional begin 
   // pragma uvmf custom package_imports_additional end
   `include "src/imem_macros.svh"

   export imem_pkg_hdl::*;
   
 

   // Parameters defined as HVL parameters

   `include "src/imem_typedefs.svh"
   `include "src/imem_transaction.svh"

   `include "src/imem_configuration.svh"
   `include "src/imem_driver.svh"
   `include "src/imem_monitor.svh"

   `include "src/imem_transaction_coverage.svh"
   `include "src/imem_sequence_base.svh"
   `include "src/imem_random_sequence.svh"

   `include "src/imem_responder_sequence.svh"
   `include "src/imem2reg_adapter.svh"

   `include "src/imem_agent.svh"

   // pragma uvmf custom package_item_additional begin
   // UVMF_CHANGE_ME : When adding new interface sequences to the src directory
   //    be sure to add the sequence file here so that it will be
   //    compiled as part of the interface package.  Be sure to place
   //    the new sequence after any base sequences of the new sequence.

   // -------------------------------------------------------------------------
   // Stimulus library (ECE 748 P3, Group 6, owner: Ziyao Lin)
   // Constrained extensions of imem_transaction. A test swaps one in with
   //   imem_transaction::type_id::set_type_override(imem_alu_transaction::get_type());
   // before super.build_phase(); the responder sequence then only answers with
   // that group (and, with no_repeat=1, sends every word of the group once).
   // Each extension adds a constraint AND the matching in_scope() filter; the
   // responder sequence checks that the two agree.
   class imem_alu_transaction extends imem_transaction;      // ADD, AND, NOT, LEA: 9,280 words
     `uvm_object_utils(imem_alu_transaction)
     constraint alu_group_c { instr[15:12] inside { IMEM_ADD, IMEM_AND, IMEM_NOT, IMEM_LEA }; }
     function new(string name = "");
       super.new(name);
     endfunction
     virtual function bit in_scope(bit [15:0] w);
       return super.in_scope(w) && (w[15:12] inside { IMEM_ADD, IMEM_AND, IMEM_NOT, IMEM_LEA });
     endfunction
   endclass

   class imem_mem_transaction extends imem_transaction;      // LD, LDI, LDR, ST, STI, STR: 24,576 words
     `uvm_object_utils(imem_mem_transaction)
     constraint mem_group_c { instr[15:12] inside { IMEM_LD, IMEM_LDI, IMEM_LDR, IMEM_ST, IMEM_STI, IMEM_STR }; }
     function new(string name = "");
       super.new(name);
     endfunction
     virtual function bit in_scope(bit [15:0] w);
       return super.in_scope(w) && (w[15:12] inside { IMEM_LD, IMEM_LDI, IMEM_LDR, IMEM_ST, IMEM_STI, IMEM_STR });
     endfunction
   endclass

   class imem_ctrl_transaction extends imem_transaction;     // BR, JMP: 4,104 words
     `uvm_object_utils(imem_ctrl_transaction)
     constraint ctrl_group_c { instr[15:12] inside { IMEM_BR, IMEM_JMP }; }
     function new(string name = "");
       super.new(name);
     endfunction
     virtual function bit in_scope(bit [15:0] w);
       return super.in_scope(w) && (w[15:12] inside { IMEM_BR, IMEM_JMP });
     endfunction
   endclass

   // Wide-open random answers instead of the permutation walk.
   // Use: imem_responder_sequence::type_id::set_type_override(imem_random_responder_sequence::get_type());
   class imem_random_responder_sequence extends imem_responder_sequence;
     `uvm_object_utils(imem_random_responder_sequence)
     function new(string name = "imem_random_responder_sequence");
       super.new(name);
       no_repeat = 1'b0;
     endfunction
   endclass

   // Short, known program for the first bring-up run on the real RTL
   // (imem_smoke_test): back-to-back ALU work, a store and loads (memory stalls,
   // LDI/STI take two), a load-use dependency, BR taken / not taken, BRnzp and
   // JMP. After the program only the filler is sent. The responder answers each
   // fetch with the next program word whatever the PC is, so branch targets
   // change the PC sequence but not the word order.
   class imem_directed_responder_sequence extends imem_responder_sequence;
     `uvm_object_utils(imem_directed_responder_sequence)
     bit [15:0] program_words[$] = '{
       16'h5020,   // AND  R0, R0, #0
       16'h1225,   // ADD  R1, R0, #5
       16'h1441,   // ADD  R2, R1, R1
       16'h96BF,   // NOT  R3, R2
       16'hE802,   // LEA  R4, #2
       16'h3203,   // ST   R1, #3
       16'h2A03,   // LD   R5, #3
       16'h1D61,   // ADD  R6, R5, #1   (uses the loaded value)
       16'h6F01,   // LDR  R7, R4, #1
       16'h7F02,   // STR  R7, R4, #2
       16'hA001,   // LDI  R0, #1
       16'hB201,   // STI  R1, #1
       16'h1260,   // ADD  R1, R1, #0   (sets the condition codes from R1)
       16'h0202,   // BRp  #2
       16'h0801,   // BRn  #1
       16'h0E00,   // BRnzp #0
       16'hC100,   // JMP  R4
       16'h5483    // AND  R2, R2, R3
     };
     protected int unsigned next_index = 0;
     virtual function int expected_target_count();
       return program_words.size();
     endfunction
     function new(string name = "imem_directed_responder_sequence");
       super.new(name);
       no_repeat = 1'b0;
     endfunction
     virtual protected function bit next_target_word(output bit closes_pass);
       bit [15:0] word;
       closes_pass = 1'b0;
       if (next_index >= program_words.size()) return 1'b0;
       word = program_words[next_index];
       next_index++;
       if (!req.randomize() with { instr == local::word; })
         `uvm_fatal("IMEM_SEQ", $sformatf("constraints of %s reject program word 0x%04h", req.get_type_name(), word))
       return 1'b1;
     endfunction
   endclass
   // pragma uvmf custom package_item_additional end

endpackage

// pragma uvmf custom external begin
// pragma uvmf custom external end

