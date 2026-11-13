
// UVM
+incdir+${UVM_HOME}/src
${UVM_HOME}/src/uvm_pkg.sv

// Common UVMF files
-f ${UVMF_HOME}/common/common_sve.f

// Sub-Environments
-F ${UVMF_VIP_LIBRARY_HOME}/environment_packages/fetch_env_pkg/fetch_env_pkg_sve.F

+incdir+.
./imem_fetch_sandbox_env_pkg.sv
