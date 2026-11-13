
// UVM
+incdir+${UVM_HOME}/src
${UVM_HOME}/src/uvm_pkg.sv

// Common UVMF files
-f ${UVMF_HOME}/common/common_sve.f

// BFM Files
-F ${UVMF_VIP_LIBRARY_HOME}/interface_packages/fetch_in_pkg/fetch_in_pkg_sve.F
-F ${UVMF_VIP_LIBRARY_HOME}/interface_packages/fetch_out_pkg/fetch_out_pkg_sve.F
-F ${UVMF_VIP_LIBRARY_HOME}/interface_packages/imem_pkg/imem_pkg_sve.F

// Environment Files
-F ${UVMF_VIP_LIBRARY_HOME}/environment_packages/imem_fetch_sandbox_env_pkg/imem_fetch_sandbox_env_pkg_sve.F

// Bench Files
+incdir+./tb/tests
./tb/tests/imem_fetch_sandbox_tests_pkg.sv

+incdir+./tb/sequences
./tb/sequences/imem_fetch_sandbox_sequences_pkg.sv

+incdir+./tb/parameters
./tb/parameters/imem_fetch_sandbox_parameters_pkg.sv

./tb/testbench/hdl_top.sv
./tb/testbench/hvl_top.sv

