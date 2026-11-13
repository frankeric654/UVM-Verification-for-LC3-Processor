//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// DESCRIPTION: This package contains all tests currently written for
//     the simulation project.  Once compiled, any test can be selected
//     from the vsim command line using +UVM_TESTNAME=yourTestNameHere
//
// CONTAINS:
//     -<test_top>
//     -<example_derived_test>
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

package imem_fetch_sandbox_tests_pkg;

   import uvm_pkg::*;
   import uvmf_base_pkg::*;
   import imem_fetch_sandbox_parameters_pkg::*;
   import imem_fetch_sandbox_env_pkg::*;
   import imem_fetch_sandbox_sequences_pkg::*;
   import fetch_in_pkg::*;
   import fetch_in_pkg_hdl::*;
   import fetch_out_pkg::*;
   import fetch_out_pkg_hdl::*;
   import imem_pkg::*;
   import imem_pkg_hdl::*;


   `include "uvm_macros.svh"

  // pragma uvmf custom package_imports_additional begin 
  // pragma uvmf custom package_imports_additional end

   `include "src/test_top.svh"
   `include "src/register_test.svh"
   `include "src/example_derived_test.svh"

  // pragma uvmf custom package_item_additional begin
  // UVMF_CHANGE_ME : When adding new tests to the src directory
  //    be sure to add the test file here so that it will be
  //    compiled as part of the test package.  Be sure to place
  //    the new test after any base tests of the new test.

  // ---------------------------------------------------------------------------
  // Sandbox tests (ECE 748 P3, Group 6, owner: Ziyao Lin). They only change
  // what the imem responder sends; Fetch checking and instruction coverage are
  // the same in all of them. Coverage goal = families that must be complete.
  //   test_top         : every legal instruction word once      goal ALU+MEM+CONTROL
  //   imem_alu_test    : ADD/AND/NOT/LEA words (9,280)           goal ALU
  //   imem_mem_test    : LD/LDI/LDR/ST/STI/STR words (24,576)    goal MEM
  //   imem_ctrl_test   : BR/JMP words (4,104)                    goal CONTROL
  //   imem_random_test : wide-open random for run_clocks         report only
  //   imem_smoke_test  : short directed program, 300 cycles      report only
  class imem_alu_test extends test_top;
    `uvm_component_utils(imem_alu_test)
    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
      imem_transaction::type_id::set_type_override(imem_alu_transaction::get_type());
      super.build_phase(phase);
      uvm_config_db #(bit [2:0])::set(this, "*", "imem_cov_required_families", 3'b001);
    endfunction
  endclass

  class imem_mem_test extends test_top;
    `uvm_component_utils(imem_mem_test)
    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
      imem_transaction::type_id::set_type_override(imem_mem_transaction::get_type());
      super.build_phase(phase);
      uvm_config_db #(bit [2:0])::set(this, "*", "imem_cov_required_families", 3'b010);
    endfunction
  endclass

  class imem_ctrl_test extends test_top;
    `uvm_component_utils(imem_ctrl_test)
    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
      imem_transaction::type_id::set_type_override(imem_ctrl_transaction::get_type());
      super.build_phase(phase);
      uvm_config_db #(bit [2:0])::set(this, "*", "imem_cov_required_families", 3'b100);
    endfunction
  endclass

  class imem_random_test extends test_top;
    `uvm_component_utils(imem_random_test)
    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
      imem_responder_sequence::type_id::set_type_override(imem_random_responder_sequence::get_type());
      super.build_phase(phase);
      uvm_config_db #(bit [2:0])::set(this, "*", "imem_cov_required_families", 3'b000);
    endfunction
  endclass

  // First run on the real RTL: short directed program, fixed length.
  class imem_smoke_test extends test_top;
    `uvm_component_utils(imem_smoke_test)
    function new(string name = "", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
      imem_responder_sequence::type_id::set_type_override(imem_directed_responder_sequence::get_type());
      imem_fetch_sandbox_bench_sequence_base::type_id::set_type_override(imem_fetch_sandbox_smoke_sequence::get_type());
      super.build_phase(phase);
      uvm_config_db #(bit [2:0])::set(this, "*", "imem_cov_required_families", 3'b000);
    endfunction
  endclass
  // pragma uvmf custom package_item_additional end

endpackage

// pragma uvmf custom external begin
// pragma uvmf custom external end

