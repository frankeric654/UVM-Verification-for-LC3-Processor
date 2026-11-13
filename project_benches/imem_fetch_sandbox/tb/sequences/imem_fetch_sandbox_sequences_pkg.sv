//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// DESCRIPTION: This package includes all high level sequence classes used 
//     in the environment.  These include utility sequences and top
//     level sequences.
//
// CONTAINS:
//     -<imem_fetch_sandbox_sequence_base>
//     -<example_derived_test_sequence>
//
//----------------------------------------------------------------------
//
//----------------------------------------------------------------------
//

package imem_fetch_sandbox_sequences_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;
  import fetch_in_pkg::*;
  import fetch_in_pkg_hdl::*;
  import fetch_out_pkg::*;
  import fetch_out_pkg_hdl::*;
  import imem_pkg::*;
  import imem_pkg_hdl::*;
  import imem_fetch_sandbox_parameters_pkg::*;
  import imem_fetch_sandbox_env_pkg::*;
  `include "uvm_macros.svh"

  // pragma uvmf custom package_imports_additional begin
  // pragma uvmf custom package_imports_additional end

  `include "src/imem_fetch_sandbox_bench_sequence_base.svh"
  `include "src/register_test_sequence.svh"
  `include "src/example_derived_test_sequence.svh"

  // pragma uvmf custom package_item_additional begin
  // UVMF_CHANGE_ME : When adding new sequences to the src directory
  //    be sure to add the sequence file here so that it will be
  //    compiled as part of the sequence package.  Be sure to place
  //    the new sequence after any base sequences of the new sequence.

  // Bring-up run for imem_smoke_test: the directed program plus filler for a
  // short, fixed number of cycles, so the first waveform is easy to read.
  class imem_fetch_sandbox_smoke_sequence extends imem_fetch_sandbox_bench_sequence_base;
    `uvm_object_utils(imem_fetch_sandbox_smoke_sequence)
    function new(string name = "");
      super.new(name);
      run_clocks   = 300;
      drain_clocks = 20;
    endfunction
  endclass
  // pragma uvmf custom package_item_additional end

endpackage

// pragma uvmf custom external begin
// pragma uvmf custom external end

