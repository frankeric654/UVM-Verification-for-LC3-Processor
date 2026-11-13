#!/usr/bin/env bash
# Verifies WB infrastructure. This is not the team's LC3 assignment regression.
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
questa_home=${QUESTA_HOME:-/mnt/apps/public/COE/mg_apps/questa2024.2/questasim}
questa_home=${questa_home%/}
export WB_BUILD_DIR=${WB_BUILD_DIR:-$(mktemp -d /tmp/ece748-wb-regress.XXXXXX)}
mkdir -p "$WB_BUILD_DIR"
WB_BUILD_DIR=$(cd "$WB_BUILD_DIR" && pwd)
export WB_BUILD_DIR
bash "$repo_root/scripts/writeback/compile.sh" \
  "$repo_root/tests/writeback/writeback_smoke_tb.sv" \
  "$repo_root/tests/writeback/writeback_scoreboard_tb.sv" > "$WB_BUILD_DIR/compile.log" 2>&1 || {
    cat "$WB_BUILD_DIR/compile.log"; exit 1;
  }
cd "$WB_BUILD_DIR"
run_case() {
  local case_name=$1 top=$2 expected_errors=$3 error_id=$4
  shift 4
  "$questa_home/bin/vsim" -c -coverage -L "$questa_home/uvm-1.2" "work.$top" \
    "$@" -do "onfinish stop; run -all; coverage save $case_name.ucdb; quit -f" \
    -l "$case_name.log" > "$case_name.console" 2>&1 || {
      cat "$case_name.console"; return 1;
    }
  test -s "$case_name.ucdb" || { printf 'Missing coverage artifact: %s\n' "$case_name.ucdb"; return 1; }
  python3 - "$case_name.log" "$expected_errors" "$error_id" <<'PY'
import re, sys
from pathlib import Path
log = Path(sys.argv[1]).read_text()
errors = re.search(r'UVM_ERROR\s*:\s*(\d+)', log)
fatals = re.search(r'UVM_FATAL\s*:\s*(\d+)', log)
assert errors and fatals, 'Missing UVM report summary (simulation did not finish)'
count = int(errors[1])
assert int(fatals[1]) == 0, 'Unexpected UVM_FATAL'
if sys.argv[2] == 'positive':
    assert count > 0, 'Injected fault was not detected'
else:
    assert count == int(sys.argv[2]), f'Unexpected error count {count}'
error_lines = [x for x in log.splitlines() if re.search(r'UVM_ERROR\b.* @', x)]
if sys.argv[3] != '-':
    assert error_lines and all(f'[{sys.argv[3]}]' in x for x in error_lines), error_lines
assert '[WB_SUMMARY]' in log, 'Missing scoreboard summary'
print(f'PASS {Path(sys.argv[1]).stem}: expected diagnostics verified, UVM_ERROR={count}')
PY
}
# Configuration-only mode reuses the previously verified scoreboard tests.
run_case smoke writeback_smoke_tb 0 -
if [[ ${WB_TEST_SUITE:-all} != configuration ]]; then
  run_case corrupt_d1 writeback_smoke_tb positive WB_MISMATCH +WB_FAULT_D1
  run_case corrupt_psr writeback_smoke_tb positive WB_MISMATCH +WB_FAULT_PSR
  run_case scoreboard writeback_scoreboard_tb 0 -
  run_case scoreboard_x writeback_scoreboard_tb 1 WB_MISMATCH +WB_UNIT_FAULT
  run_case pending writeback_scoreboard_tb 1 WB_PENDING +WB_PENDING
  run_case duplicate writeback_scoreboard_tb 1 WB_DUPLICATE +WB_DUPLICATE
fi
run_config_failure() {
  local case_name=$1 expected_id=$2 option=$3
  "$questa_home/bin/vsim" -c -L "$questa_home/uvm-1.2" work.writeback_smoke_tb \
    "$option" -do 'onfinish stop; run -all; quit -f' \
    -l "$case_name.log" > "$case_name.console" 2>&1 || true
  python3 - "$case_name.log" "$expected_id" <<'PYCONFIG'
import re, sys
from pathlib import Path
log = Path(sys.argv[1]).read_text()
assert re.search(r'UVM_FATAL\s*:\s*1\b', log), 'Expected exactly one fatal'
assert re.search(r'UVM_ERROR\s*:\s*0\b', log), 'Unexpected UVM errors'
lines = [x for x in log.splitlines() if re.search(r'UVM_FATAL\b.* @', x)]
assert len(lines) == 1 and f'[{sys.argv[2]}]' in lines[0], lines
assert '@ 0:' in lines[0], 'Configuration failure must occur during initialization'
print(f'PASS {Path(sys.argv[1]).stem}: expected initialization fatal {sys.argv[2]}')
PYCONFIG
}
run_config_failure missing_config NO_CONFIG +WB_MISSING_CONFIG
run_config_failure null_bfm NO_BFM +WB_NULL_BFM
"$questa_home/bin/vcover" report -cvg -details smoke.ucdb -output wb-functional-coverage.txt \
  > coverage-report.log 2>&1
printf 'WB regression artifacts: %s\n' "$WB_BUILD_DIR"
