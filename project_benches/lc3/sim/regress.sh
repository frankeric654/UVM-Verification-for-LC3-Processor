#!/usr/bin/env bash
set -euo pipefail

sim_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

exec "${LC3_PYTHON:-python3}" - "$sim_dir" "$@" <<'PY'
from pathlib import Path
import argparse
import json
import shlex
import os
import re
import subprocess
import sys
import tempfile
import time

start = time.perf_counter()
sim = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(sim))
from sim_checks import read_sim_summary
from sim_paths import (
    resolve_tools, resolve_rtl, env_words, extra_sources
)
repo = sim.parents[2]

ap = argparse.ArgumentParser()
ap.add_argument("--characterize", action="store_true")
ap.add_argument("--seed", type=int, default=1)
ap.add_argument("--timeout", type=int,
                default=os.getenv("LC3_TOOL_TIMEOUT", "300"))
ap.add_argument("--out-root", type=Path, default=sim / "build")
args = ap.parse_args(sys.argv[2:])

if args.timeout <= 0 or args.seed <= 0:
    ap.error("seed and timeout must be positive")

try:
    questa, uvmf = resolve_tools(
        os.getenv("QUESTA_HOME"),
        os.getenv("UVMF_HOME")
    )

    rtl = resolve_rtl(repo, os.getenv("LC3_RTL_DIR"))

    additional_tops = env_words("EXTRA_VOPT_TOPS")

    # Resolve user-provided source paths before entering
    # the temporary compilation directory.
    os.environ["EXTRA_SV_SOURCES"] = " ".join(
        shlex.quote(str(p)) for p in extra_sources()
    )

except ValueError as exc:
    ap.error(str(exc))

args.out_root = args.out_root.resolve()
args.out_root.mkdir(parents=True, exist_ok=True)

work = Path(tempfile.mkdtemp(
    prefix="regress.",
    dir=args.out_root
))

print("REGRESSION OUTPUT:", work, flush=True)
print("MODE:", "CHARACTERIZATION" if args.characterize
      else "STRICT", flush=True)

timings = {}
known_issue = False

test_results = {}
test_failures = []
coverage_scope = "NOT_MERGED"


def write_status(status, reason=""):
    result = {
        "mode": "CHARACTERIZATION" if args.characterize else "STRICT",
        "status": status,
        "reason": reason,
        "seed": args.seed,
        "tests": test_results,
        "coverage_scope": coverage_scope,
        "timings_seconds": timings,
        "total_wall_seconds": time.perf_counter() - start
    }

    (work / "regression_status.json").write_text(
        json.dumps(result, indent=2) + "\n"
    )


def require(condition, message):
    if not condition:
        raise RuntimeError(message)

def run(label, command, logfile):
    t = time.perf_counter()

    print(f"\n===== {label} =====", flush=True)

    with logfile.open("w") as f:
        result = subprocess.run(
            command, cwd=work,
            stdout=f, stderr=subprocess.STDOUT,
            timeout=(2 * args.timeout + 10
                     if label == "COMPILE" else args.timeout)
        )

    timings[label] = time.perf_counter() - t

    print(f"{label}: {timings[label]:.3f} s", flush=True)

    if result.returncode:
        print(logfile.read_text()[-5000:])
        raise RuntimeError(f"{label} failed")

def one(pattern, log):
    matches = re.findall(pattern, log, re.M)
    require(len(matches) == 1, f"Invalid summary: {pattern}")
    return matches[0]

def validate(log, test_kind):
    global known_issue

    errors, fatals = read_sim_summary(log)
    require(fatals == 0, "UVM fatal")

    if errors and args.characterize:
        reports = re.findall(
            r"^# UVM_ERROR .*control_env\.scoreboard "
            r"\[CONTROL_MISMATCH\] expected: ([^\n]+)\n"
            r"# actual:\s+([^\n]+)",
            log, re.M
        )

        require(errors == len(reports) == 4,
                "Unexpected UVM errors")

        for cycle, (expected, actual) in enumerate(reports, 2):
            e = dict(re.findall(r"(\w+)=(\S+)", expected))
            a = dict(re.findall(r"(\w+)=(\S+)", actual))

            required = {
                "cycle": str(cycle),
                "reset": "1",
                "enable_updatePC": "0",
                "enable_fetch": "0",
                "enable_decode": "0",
                "enable_execute": "0",
                "enable_writeback": "0",
                "bypass_alu_1": "0",
                "bypass_alu_2": "0",
                "bypass_mem_1": "0",
                "bypass_mem_2": "0",
                "mem_state": "11",
                "br_taken": "0"
            }

            require(e == required, "Unknown reset prediction")
            required["enable_fetch"] = "1"
            require(a == required, "Unknown reset observation")

        known_issue = True

    f = one(
        r"SCOREBOARD_RESULTS: +PREDICTED_TRANSACTIONS=(\d+) "
        r"MATCHES=(\d+) MISMATCHES=0$", log
    )

    require(int(f[0]) == int(f[1]) > 0, "Fetch accounting")

    for stage in ("decode", "mem_access"):
        e, c = map(int, one(
            rf"{stage}_env\.scoreboard \[SCOREBOARD_REPORT\]\s*\n"
            r"#\s*\n"
            r"# Expected transactions received: (\d+)\s*\n"
            r"# Comparisons made: (\d+)\s*\n"
            r"# Mismatches: 0\s*\n"
            r"# Expected transactions remaining: 0$",
            log
        ))

        require(e == c > 0, f"{stage} accounting")

    e, a, m, skip = map(int, one(
        r"\[EXE_SB\] Expected=(\d+) Actual=(\d+) Match=(\d+) "
        r"Mismatch=0 Skipped=(\d+) NoExpected=0 Remaining=0$",
        log
    ))

    require(e == a == m + skip and m > 0 and skip <= 1,
            "Execute accounting")

    pairs, checks, unchecked = map(int, one(
        r"\[WB_SUMMARY\] pairs=(\d+) field_checks=(\d+) "
        r"mismatches=0 unchecked_pairs=(\d+)$", log
    ))

    require(pairs > 0 and checks > 0 and unchecked <= 9,
            "Writeback accounting")

    e, a, c, m, bad = map(int, one(
        r"\[CONTROL_SCOREBOARD\] expected=(\d+) actual=(\d+) "
        r"compared=(\d+) matched=(\d+) mismatched=(\d+) pending=0$",
        log
    ))

    require(e == a == c == m + bad and m > 0 and bad == errors,
            "Control accounting")

    if test_kind == "exhaustive":
        require(re.search(
            r"\[LC3_ENUM_DONE\] expected=37960 delivered=37960 "
            r"passes=1 observed=\d+ protocol_errors=0 "
            r"digest=[0-9a-fA-F]+", log
        ), "Exhaustive stimulus incomplete")

        require(
            "instruction field combinations hit: 37960 of 37960" in log,
            "Instruction coverage incomplete"
        )
    elif test_kind == "directed":
        require("Delivered=148 Expected=148" in log,
                "Directed stimulus incomplete")
        require("Completed 300 clocks" in log,
                "Directed test did not finish")
    else:
        require("Delivered=198 Expected=198" in log,
                "Controller-target stimulus incomplete")
        require("Completed 5000 clocks" in log,
                "Controller-target test did not finish")

    if errors:
        print("CHECKING: KNOWN_ISSUE" if args.characterize
              else "CHECKING: FAIL")
    else:
        print("CHECKING: PASS")

    for line in log.splitlines():
        if any(k in line for k in (
            "[LC3_ENUM_DONE] expected=",
            "[FETCH_DIRECTED_DONE] Delivered=",
            "[LC3_CONTROLLER_TARGET_DONE] Delivered=",
            "[IMEM_COV] instruction",
            "[FETCH_TARGET_COV] fetch",
            "[CONTROL_SCOREBOARD] expected=",
            "SCOREBOARD_RESULTS:",
            "UVM_ERROR :",
            "UVM_FATAL :",
            "# Errors:"
        )):
            print(line)

    require(
        args.characterize or errors == 0,
        f"Strict regression has {errors} UVM errors"
    )


try:
    run("COMPILE", [
        sys.executable, str(sim / "run.py"),
        "--rtl-dir", str(rtl),
        "--uvmf-home", str(uvmf),
        "--questa-home", str(questa),
        "--out", str(work),
        "--timeout", str(args.timeout),
        "--compile-only"
    ], work / "build.log")

    require(re.search(
        r"^Errors: 0, Warnings: 0$",
        (work / "compile.log").read_text(), re.M
    ), "Compilation summary failed")

    run("OPTIMIZE", [
        str(questa / "bin/vopt"),
        "-L", str(questa / "uvm-1.2"),
        "hdl_top", "hvl_top", *additional_tops,
        "-o", "lc3_compete_opt"
    ], work / "optimize.log")

    databases = []

    tests = [
        ("exhaustive", "lc3_exhaustive_test", 500000, ()),
        ("directed", "lc3_fetch_target_test", 300, ()),
        ("controller", "lc3_controller_target_test", 5000, (
            "+LC3_DMEM_DELAY_SWEEP",
            "+LC3_DMEM_COVERAGE_INIT"
        ))
    ]

    for label, test, cycles, extra_args in tests:
        out = work / label
        out.mkdir()

        ucdb = out / "coverage.ucdb"
        logfile = out / "simulation.log"

        cmd = [
            str(questa / "bin/vsim"),
            "-c", "-coverage", "-onfinish", "stop",
            "-L", str(questa / "uvm-1.2"),
            "lc3_compete_opt",
            "-sv_seed", str(args.seed),
            f"+UVM_TESTNAME={test}",
            f"+LC3_CYCLES={cycles}",
            "+UVM_VERBOSITY=UVM_LOW",
            "+LC3_QUIET_DECODE",
            "+LC3_CONTROL_ZERO_NOP",
            *extra_args
        ]

        cmd += [
            "-do",
            f"onerror {{quit -code 2}}; "
            f"coverage save -onexit -testname {label} "
            f"{{{ucdb}}}; run -all; quit -code 0"
        ]

        record = {
            "status": "FAIL",
            "ucdb_included": False
        }

        test_results[label] = record

        try:
            run(label, cmd, logfile)

            log = logfile.read_text()

            errors, fatals = read_sim_summary(log)

            record["uvm_errors"] = errors
            record["uvm_fatals"] = fatals

            require(fatals == 0, "UVM fatal")

            # A database is eligible for diagnostic collection
            # only after a normal, completed simulation.
            if label == "exhaustive":
                marker = r"^# UVM_INFO .*\[LC3_ENUM_DONE\] expected="
            elif label == "controller":
                marker = (
                    r"^# UVM_INFO .*\[LC3_SMOKE\] "
                    r"Completed 5000 clocks;"
                )
            else:
                marker = (
                    r"^# UVM_INFO .*\[LC3_SMOKE\] "
                    r"Completed 300 clocks;"
                )

            require(
                re.search(marker, log, re.M),
                "Missing test completion marker"
            )

            require(
                ucdb.is_file() and ucdb.stat().st_size > 0,
                f"Missing UCDB: {label}"
            )

            # Preserve coverage even when functional checking fails.
            # Such data is diagnostic, never a sign-off PASS.
            databases.append(ucdb)
            record["ucdb_included"] = True

            validate(log, label)

            record["status"] = (
                "KNOWN_ISSUE" if errors else "PASS"
            )

        except (
            RuntimeError,
            OSError,
            ValueError,
            subprocess.SubprocessError
        ) as exc:
            record["reason"] = str(exc)
            test_failures.append(label)

            print(f"TEST FAILED: {label}: {exc}")
            print("Continuing with remaining tests.")

    print("\n===== TEST OUTCOMES =====")

    for label, record in test_results.items():
        print(
            label,
            record["status"],
            "UCDB included=" + str(record["ucdb_included"])
        )

    print(f"UCDB INPUTS: {len(databases)}/{len(tests)}")

    require(databases, "No completed-test UCDBs available")

    merged = work / "merged.ucdb"

    run("MERGE", [
        str(questa / "bin/vcover"), "merge",
        str(merged), *map(str, databases)
    ], work / "merge.log")

    require(
        "Errors: 0, Warnings: 0" in
        (work / "merge.log").read_text(),
        "Coverage merge warning or error"
    )

    require(merged.is_file() and merged.stat().st_size > 0,
            "Missing merged coverage")

    coverage_scope = (
        "ALL_COMPLETED_TESTS"
        if len(databases) == len(tests)
        else "PARTIAL_DIAGNOSTIC"
    )

    print("COVERAGE SCOPE:", coverage_scope)

    summary = work / "coverage_summary.txt"

    run("SUMMARY", [
        str(questa / "bin/vcover"),
        "report", "-cvg",
        "-output", str(summary), str(merged)
    ], work / "summary.log")

    require(summary.is_file() and summary.stat().st_size > 0,
            "Missing coverage summary")

    # Internal exact-bin gate. Do not include this detailed
    # diagnostic report in the course submission.
    report = work / "coverage_details.txt"

    run("REPORT", [
        str(questa / "bin/vcover"),
        "report", "-cvg", "-details",
        "-output", str(report), str(merged)
    ], work / "report.log")

    data = report.read_text()

    for stage, total in (("in", 15), ("out", 9)):
        pattern = (
            rf"^\s*TYPE /fetch_{stage}_pkg/[^\n]*"
            rf"/fetch_{stage}_behavior_cg[ \t]*\n"
            r"[^\n]*\n"
            r"\s*covered/total bins:\s*(\d+)\s+(\d+)"
        )

        rows = re.findall(pattern, data, re.M)

        require(
            rows and all(int(a) == int(b) == total
                         for a, b in rows),
            f"Fetch {stage} coverage not closed"
        )

        print(f"FETCH {stage.upper()}: {total}/{total}")

    print("\n===== REGRESSION TIMINGS =====")

    for label, elapsed in timings.items():
        print(f"{label}: {elapsed:.3f} s")

    print(f"TOTAL WALL TIME: {time.perf_counter()-start:.3f} s")
    print("OUTPUT:", work)

    require(
        len(databases) == len(tests),
        "Incomplete coverage database collection"
    )

    require(
        not test_failures,
        "Failed tests: " + ", ".join(test_failures)
    )

    if known_issue or args.characterize:
        write_status(
            "CHARACTERIZATION",
            "Not final verification sign-off"
        )
        print("CHARACTERIZATION COMPLETE — NOT FINAL SIGN-OFF")
        sys.exit(2)

    write_status("PASS")
    print("STRICT REGRESSION: PASS")

except (RuntimeError, OSError, ValueError,
        subprocess.SubprocessError) as exc:
    write_status("FAIL", str(exc))
    print("REGRESSION FAIL:", exc)
    print("OUTPUT:", work)
    sys.exit(1)
PY
