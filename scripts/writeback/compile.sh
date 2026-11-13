#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
questa_home=${QUESTA_HOME:-/mnt/apps/public/COE/mg_apps/questa2024.2/questasim}
questa_home=${questa_home%/}
model_dir=${LC3_PREDICTION_DIR:-$(dirname "$repo_root")/lc3_prediction_pkg}
build_dir=${WB_BUILD_DIR:-$(mktemp -d /tmp/ece748-wb.XXXXXX)}
mkdir -p "$build_dir"
build_dir=$(cd "$build_dir" && pwd)
cd "$build_dir"
"$questa_home/bin/vlib" work
in_dir="$repo_root/verification_ip/interface_packages/writeback_in_pkg"
out_dir="$repo_root/verification_ip/interface_packages/writeback_out_pkg"
env_dir="$repo_root/verification_ip/environment_packages/writeback_env_pkg"
"$questa_home/bin/vlog" +cover=bcesft -sv -timescale 1ns/1ps -work work \
  -L "$questa_home/uvm-1.2" \
  "+incdir+$questa_home/verilog_src/uvm-1.2/src" \
  "+incdir+$model_dir" "+incdir+$in_dir/src" "+incdir+$out_dir/src" "+incdir+$env_dir/src" \
  "$model_dir/lc3_prediction_pkg.sv" \
  "$in_dir/src/writeback_in_types_pkg.sv" \
  "$out_dir/src/writeback_out_types_pkg.sv" \
  "$in_dir/src/writeback_in_if.sv" "$in_dir/src/writeback_in_monitor_bfm.sv" \
  "$out_dir/src/writeback_out_if.sv" "$out_dir/src/writeback_out_monitor_bfm.sv" \
  "$in_dir/writeback_in_pkg.sv" "$out_dir/writeback_out_pkg.sv" \
  "$env_dir/writeback_env_pkg.sv" "$@"
printf 'WB build directory: %s\n' "$build_dir"
