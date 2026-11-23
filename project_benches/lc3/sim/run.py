#!/usr/bin/env python3
"""Build and run both LC3 tops with all six stage environments (Questa/UVM 1.2)."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--rtl-dir', type=Path, default=os.getenv('LC3_RTL_DIR'))
    ap.add_argument('--uvmf-home', type=Path, default=os.getenv('UVMF_HOME'))
    ap.add_argument('--questa-home', type=Path, default=os.getenv('QUESTA_HOME'))
    ap.add_argument('--out', type=Path, default=Path(__file__).parent / 'build')
    ap.add_argument('--compile-only', action='store_true')
    ap.add_argument('--seed', type=int, default=1)
    ap.add_argument('--cycles', type=int, default=300)
    args = ap.parse_args()
    for key in ['rtl_dir', 'uvmf_home', 'questa_home']:
        val = getattr(args, key)
        if val is None or not val.is_dir():
            ap.error('--' + key.replace('_', '-') + ' must name an existing directory')
        setattr(args, key, val.resolve())
    root = Path(__file__).resolve().parents[3]
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    vip = root / 'verification_ip'
    uvm = args.questa_home / 'verilog_src/uvm-1.2/src'
    inc = [uvm, args.uvmf_home / 'uvmf_base_pkg', args.uvmf_home / 'uvmf_base_pkg/src',
           args.rtl_dir, root / 'integration/writeback']
    sources = [args.uvmf_home / 'uvmf_base_pkg/uvmf_base_pkg_hdl.sv',
               args.uvmf_home / 'uvmf_base_pkg/uvmf_base_pkg.sv',
               vip / 'prediction_packages/lc3_prediction_pkg/lc3_prediction_pkg.sv']
    inc.append(sources[-1].parent)
    # Compile package headers and circular class/BFM references together (-mfcu).
    agents = ['fetch_in', 'fetch_out', 'imem', 'decode_in', 'decode_out',
              'execute_in', 'execute_out', 'mem_access_in', 'mem_access_out',
              'writeback_in', 'writeback_out', 'control_in', 'control_out']
    for name in agents:
        d = vip / 'interface_packages' / (name + '_pkg')
        inc += [d, d / 'src']
        for f in [d / (name + '_pkg_hdl.sv'), d / 'src' / (name + '_types_pkg.sv')]:
            if f.exists(): sources.append(f)
        sources.append(d / 'src' / (name + '_if.sv'))
        # Config classes can refer to these BFMs; several BFMs also refer back
        # to classes. Questa resolves these within the same compilation unit.
        sources.append(d / (name + '_pkg.sv'))
        sources += sorted((d / 'src').glob('*_driver_bfm.sv'))
        sources += sorted((d / 'src').glob('*_monitor_bfm.sv'))
    for name in ['fetch', 'decode', 'execute', 'mem_access', 'writeback', 'control', 'lc3']:
        d = vip / 'environment_packages' / (name + '_env_pkg')
        inc += [d, d / 'src']
        sources.append(d / (name + '_env_pkg.sv'))
    tests = root / 'project_benches/lc3/tb/tests/lc3_test_pkg'
    inc += [tests, tests / 'src']
    sources.append(tests / 'lc3_test_pkg.sv')
    sources += [args.rtl_dir / f for f in ['Fetch.v', 'Decode_Pipelined.v', 'Execute.v',
                'Mem_Access.v', 'WriteBack.v', 'Controller_Pipeline.v', 'TopLevelLC3.v']]
    top = root / 'project_benches/lc3/tb/testbench'
    sources += [top / 'lc3_dmem_model.sv', top / 'hdl_top.sv', top / 'hvl_top.sv']
    for f in sources:
        if not f.is_file(): ap.error('Missing source: ' + str(f))
    def run(tool, argv, log):
        with (out / log).open('w') as stream:
            result = subprocess.run([str(args.questa_home / 'bin' / tool), *map(str, argv)],
                                    cwd=out, stdout=stream, stderr=subprocess.STDOUT, timeout=180)
        print(tool, 'exit', result.returncode, 'log:', out / log, flush=True)
        if result.returncode:
            print((out / log).read_text()[-10000:])
            raise SystemExit(result.returncode)
    if not (out / 'work').exists(): run('vlib', ['work'], 'vlib.log')
    run('vlog', ['-sv', '-mfcu', '-timescale', '1ns/1ps', '-L', args.questa_home / 'uvm-1.2',
                *['+incdir+' + str(x) for x in inc], *sources], 'compile.log')
    if args.compile_only: return
    run('vsim', ['-c', '-L', args.questa_home / 'uvm-1.2', 'hdl_top', 'hvl_top',
                 '-sv_seed', args.seed, '+UVM_TESTNAME=lc3_smoke_test',
                 '+LC3_CYCLES=' + str(args.cycles), '+UVM_VERBOSITY=UVM_LOW',
                 '-do', 'onerror {quit -code 2}; run 100us; quit -code 0'], 'simulation.log')
    log = (out / 'simulation.log').read_text()
    counts = [int(n) for n in re.findall(r'UVM_(?:ERROR|FATAL)\s*:\s*(\d+)', log)]
    if 'LC3_SMOKE' not in log or len(counts) < 2 or any(counts) or re.search(r'\*\* (?:Error|Fatal)', log):
        print('Simulation did not pass. Inspect simulation.log; errors are not suppressed.')
        raise SystemExit(1)
    print('LC3 smoke passed (not coverage closure).')

if __name__ == '__main__':
    main()
