#!/usr/bin/env python3
"""Validate the 300-cycle LC3 integration baseline."""

import re
import sys
from pathlib import Path
from sim_checks import read_sim_summary


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(run, rc):
    compile_log = (run / "compile.log").read_text()
    log = (run / "simulation.log").read_text()

    def one(pattern):
        matches = re.findall(pattern, log, re.MULTILINE)
        require(len(matches) == 1, f"Missing or duplicate result: {pattern}")
        return matches[0]

    require(
        re.search(r"^Errors: 0, Warnings: 0$", compile_log, re.M),
        "Compilation failed or produced warnings"
    )

    errors, fatals = read_sim_summary(log)

    responses = one(
        r"^# UVM_INFO .*"
        r"\[LC3_SMOKE\] Completed 300 clocks; imem responses=(\d+)$"
    )
    require(int(responses) > 0, "No IMEM responses")


    require(fatals == 0, "UVM fatal detected")

    one(
        r"^# UVM_INFO .*fetch_env\.fetch_sb "
        r"\[SCBD\] SCOREBOARD_RESULTS:\s+"
        r"PREDICTED_TRANSACTIONS=301 MATCHES=301 MISMATCHES=0$"
    )

    for stage in ("decode", "mem_access"):
        one(
            rf"^# UVM_INFO .*{stage}_env\.scoreboard "
            r"\[SCOREBOARD_REPORT\]\s*\n"
            r"#\s*\n"
            r"# Expected transactions received: 301\s*\n"
            r"# Comparisons made: 301\s*\n"
            r"# Mismatches: 0\s*\n"
            r"# Expected transactions remaining: 0$"
        )

    matches, skipped = map(int, one(
        r"^# UVM_INFO .*execute_env\.scoreboard "
        r"\[EXE_SB\] Expected=306 Actual=306 "
        r"Match=(\d+) Mismatch=0 Skipped=(\d+) "
        r"NoExpected=0 Remaining=0$"
    ))

    require(
        matches + skipped == 306 and skipped <= 1,
        "Execute comparison accounting changed"
    )

    checks, unchecked = map(int, one(
        r"^# UVM_INFO .*writeback_env\.scoreboard "
        r"\[WB_SUMMARY\] pairs=306 field_checks=(\d+) "
        r"mismatches=0 unchecked_pairs=(\d+)$"
    ))

    require(
        checks >= 883 and unchecked <= 9,
        "Writeback checking regressed"
    )

    matched, mismatched = map(int, one(
        r"^# UVM_INFO .*control_env\.scoreboard "
        r"\[CONTROL_SCOREBOARD\] expected=305 actual=305 "
        r"compared=305 matched=(\d+) mismatched=(\d+) pending=0$"
    ))

    require(matched + mismatched == 305, "Control accounting mismatch")

    lines = log.splitlines()

    reports = [
        i for i, line in enumerate(lines)
        if re.match(r"^# UVM_(ERROR|FATAL)\b(?![ \t]*:)", line)
    ]

    require(len(reports) == errors, "UVM error accounting mismatch")

    if errors == 0:
        require(rc == 0 and mismatched == 0, "Inconsistent PASS")
        return "PASS"

    require(rc == 1, "Unexpected runner exit status")
    require(errors == 4 and mismatched == 4, "Unexpected error count")

    cycles = []

    for i in reports:
        line = lines[i]

        require(
            "uvm_test_top.env.control_env.scoreboard "
            "[CONTROL_MISMATCH] expected:" in line,
            "Unexpected UVM error"
        )

        expected = dict(re.findall(
            r"(\w+)=(\S+)", line.split("expected:", 1)[1]
        ))

        actual = dict(re.findall(r"(\w+)=(\S+)", lines[i + 1]))

        required = {
            "cycle": expected.get("cycle"),
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
            "br_taken": "0",
        }

        require(expected == required, "Unexpected reset prediction")

        required["enable_fetch"] = "1"

        require(actual == required, "New Control mismatch")

        cycles.append(int(expected["cycle"]))

    require(cycles == [2, 3, 4, 5], "Known issue signature changed")

    return "KNOWN_ISSUE"


if __name__ == "__main__":
    try:
        result = validate(Path(sys.argv[1]), int(sys.argv[2]))
        print(f"BASELINE: {result}")
    except (OSError, ValueError, IndexError) as exc:
        print(f"BASELINE: FAIL - {exc}", file=sys.stderr)
        sys.exit(1)
