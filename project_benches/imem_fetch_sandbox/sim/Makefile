
#
#----------------------------------------------------------------------
#                                          
# DESCRIPTION: This makefile includes the shared makefile and contains
#   bench level make targets.
#
#----------------------------------------------------------------------


# pragma uvmf custom additional begin
# pragma uvmf custom additional end

# *********************************************************************************************
# UVMF library directory:
# This variable points to the UVMF release where uvmf_base_pkg directory resides.
# This variable points to release code that is not user modified.
# This variable allows for UVMF release directories to reside independent of project related verification IP and project bench directories.
# This code below looks "upward" for directory starting with UVMF_* and returns first match for use with the release examples.
UVMF_HOME ?= ___PLEASE_SET_AN_ENVIRONMENT_VARIABLE_NAMED_UVMF_HOME_TO_POINT_TO_THE_UVMF_INSTALLATION___

# pragma uvmf custom exports begin
#
# Project(s) specific verification IP library:
# Directory where reusable verification packages for interfaces, environments, utilities, etc. reside.
# This variable allows for your verification IP to reside independent of project bench and UVMF release directories.
# For examples deployed with UVMF this will be $(UVMF_HOME)/<example_group>/verification_ip
export UVMF_VIP_LIBRARY_HOME ?= $(PWD)/../../../verification_ip
#
# Project specific bench:
# Directory where bench specific code is located.
# This variable allows for project_benches to reside independent of verification IP and UVMF release directories.
# For examples deployed with UVMF this will be $(UVMF_HOME)/<example_group>/project_benches/<example_bench>
export UVMF_PROJECT_DIR ?= $(PWD)/..
#
#
# pragma uvmf custom exports end
# *********************************************************************************************

## Check PATH for required vinfo scripts
PVAL := $(shell command -v make_filelist.py 2> /dev/null)
ifndef PVAL
  MFLIST = $(UVMF_HOME)/scripts/make_filelist.py
else
  MFLIST = make_filelist.py
endif


# Set test case specific Variables
TEST_NAME            ?= test_top

TEST_SEED            ?= random
UVM_CLI_ARGS         = 

# Usage of Veloce, etc. to be input by the user (subject to defaults)
USE_VELOCE          ?= 0

# Usage of vinfo flow for generating file list
USE_VINFO           ?= 0

# Usage of Veloce and Questa profilers
USE_VELOCE_PROFILER ?= 0
USE_QUESTA_PROFILER ?= 0


# Set project Variables
TEST_PLAN_NAME       = imem_fetch_sandbox_TestPlan
REPORTING_DO_FILE    = imem_fetch_sandbox_reports_script


# Include makefile that includes targets for UVM_VIP_Library packages
include $(UVMF_HOME)/scripts/Makefile




# Include all requisite interface package targets for this bench
include $(UVMF_VIP_LIBRARY_HOME)/interface_packages/fetch_in_pkg/Makefile
include $(UVMF_VIP_LIBRARY_HOME)/interface_packages/fetch_out_pkg/Makefile
include $(UVMF_VIP_LIBRARY_HOME)/interface_packages/imem_pkg/Makefile

# Include all requisite environment package targets for this bench
include $(UVMF_VIP_LIBRARY_HOME)/environment_packages/imem_fetch_sandbox_env_pkg/Makefile



# Add to default compile/load/run arguments
VCOM_ARGS             += 

# Note: vsim-3009 error can be eliminated by adding -timescale 1ps/1ps to VLOG_ARGS

VLOG_ARGS             += $(UVM_DISABLE_FILE_LINE_CMD)

VELANALYZE_ARGS       +=
VELANALYZE_HVL_ARGS   +=

BATCH_VOPT_ARGS       +=
DEBUG_VOPT_ARGS       +=
EXTRA_VOPT_TOPS       += 
COMMON_VSIM_ARGS      +=  
COMMON_VSIM_ARGS      +=  


BATCH_VSIM_ARGS       += #-uvmcontrol=none
DEBUG_VSIM_ARGS       += 
EXTRA_VSIM_TOPS       += 

# pragma uvmf custom additional_args begin
# pragma uvmf custom additional_args end


# Project bench package source
imem_fetch_sandbox_PARAMETERS_PKG ?=\
$(UVMF_PROJECT_DIR)/tb/parameters/imem_fetch_sandbox_parameters_pkg.sv


imem_fetch_sandbox_SEQUENCES_PKG ?=\
$(UVMF_PROJECT_DIR)/tb/sequences/imem_fetch_sandbox_sequences_pkg.sv


imem_fetch_sandbox_TEST_PKG ?=\
$(UVMF_PROJECT_DIR)/tb/tests/imem_fetch_sandbox_tests_pkg.sv

# pragma uvmf custom dut_files begin
# LC3 RTL as provided on Moodle (encrypted stage modules + TopLevelLC3.v).
# v3 includes the unchanged files from the user's submitted P2 package.
LC3_RTL_DIR ?= $(UVMF_PROJECT_DIR)/rtl
imem_fetch_sandbox_VERILOG_DUT ?= \
$(LC3_RTL_DIR)/TopLevelLC3.v \
$(LC3_RTL_DIR)/Fetch.v \
$(LC3_RTL_DIR)/Decode_Pipelined.v \
$(LC3_RTL_DIR)/Execute.v \
$(LC3_RTL_DIR)/Mem_Access.v \
$(LC3_RTL_DIR)/WriteBack.v \
$(LC3_RTL_DIR)/Controller_Pipeline.v
# pragma uvmf custom dut_files end


# Project bench package targets
COMP_imem_fetch_sandbox_PARAMETERS_PKG_TGT_0 = q_comp_imem_fetch_sandbox_parameters_pkg
COMP_imem_fetch_sandbox_PARAMETERS_PKG_TGT_1 = v_comp_imem_fetch_sandbox_parameters_pkg
COMP_imem_fetch_sandbox_PARAMETERS_PKG_TGT = $(COMP_imem_fetch_sandbox_PARAMETERS_PKG_TGT_$(USE_VELOCE))

comp_imem_fetch_sandbox_parameters_pkg: $(COMP_imem_fetch_sandbox_PARAMETERS_PKG_TGT)

q_comp_imem_fetch_sandbox_parameters_pkg:
	        $(HVL_COMP_CMD) +incdir+$(UVMF_PROJECT_DIR)/tb/parameters $(imem_fetch_sandbox_PARAMETERS_PKG)

v_comp_imem_fetch_sandbox_parameters_pkg: q_comp_imem_fetch_sandbox_parameters_pkg
	$(HDL_COMP_CMD) +incdir+$(UVMF_PROJECT_DIR)/tb/parameters $(imem_fetch_sandbox_PARAMETERS_PKG)
 

comp_imem_fetch_sandbox_sequence_pkg:
	$(HVL_COMP_CMD) +incdir+$(UVMF_PROJECT_DIR)/tb/sequences $(imem_fetch_sandbox_SEQUENCES_PKG)

comp_imem_fetch_sandbox_tests_pkg:
	$(HVL_COMP_CMD) +incdir+$(UVMF_PROJECT_DIR)/tb/tests $(imem_fetch_sandbox_TEST_PKG)

# pragma uvmf custom dut_compile_make_target begin
comp_imem_fetch_sandbox_verilog_dut:
	$(HDL_COMP_CMD) +incdir+$(LC3_RTL_DIR) $(imem_fetch_sandbox_VERILOG_DUT)
comp_imem_fetch_sandbox_vhdl_dut:
	@echo "No VHDL source in the LC3 sandbox bench"
comp_imem_fetch_sandbox_dut: comp_imem_fetch_sandbox_verilog_dut
# pragma uvmf custom dut_compile_make_target end


BUILD_TGT_0 = make_build
BUILD_TGT_1 = vinfo_build
BUILD_TGT = $(BUILD_TGT_$(USE_VINFO))


comp_hvl : comp_hvl_core


comp_hvl_core :   \
	 comp_fetch_in_pkg  comp_fetch_out_pkg  comp_imem_pkg  \
	comp_imem_fetch_sandbox_env_pkg \
	comp_imem_fetch_sandbox_parameters_pkg comp_imem_fetch_sandbox_sequence_pkg comp_imem_fetch_sandbox_tests_pkg 

comp_uvmf_core : comp_uvm_pkg comp_uvmf_base_pkg 

make_build: comp_imem_fetch_sandbox_dut comp_uvmf_core comp_hvl comp_test_bench  

hvl_build:  q_comp_fetch_in_pkg  q_comp_fetch_out_pkg  q_comp_imem_pkg  comp_imem_fetch_sandbox_env_pkg comp_imem_fetch_sandbox_sequence_pkg comp_imem_fetch_sandbox_tests_pkg hvl_comp_testbench link optimize


vinfo_build: comp_imem_fetch_sandbox_vhdl_dut  build_hdl_vinfo build_hvl_vinfo $(VINFO_TGT)

	$(HDL_COMP_CMD) -F hdl.vf
	$(VEL_COMP)

build: $(BUILD_TGT)

# pragma uvmf custom additional_targets begin
# pragma uvmf custom additional_targets end

