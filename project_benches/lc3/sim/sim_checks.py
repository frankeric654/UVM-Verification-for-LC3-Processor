"""Shared Questa and UVM transcript integrity checks."""

import re


def read_sim_summary(log):
    counts = {}

    for severity in ("ERROR", "FATAL"):
        pattern = (
            rf"^# UVM_{severity}[ \t]*:"
            r"[ \t]*(\d+)[ \t]*$"
        )
        matches = list(re.finditer(pattern, log, re.M))

        if len(matches) != 1:
            raise ValueError(f"Missing or duplicate UVM_{severity} summary")

        counts[severity] = int(matches[0].group(1))

        reports = re.findall(
            rf"^# UVM_{severity}\b(?![ \t]*:)",
            log, re.M
        )

        if len(reports) != counts[severity]:
            raise ValueError(f"UVM_{severity} accounting mismatch")

    summaries = list(re.finditer(
        r"^[ \t]*(?:#[ \t]*)?Errors:[ \t]*(\d+),"
        r"[ \t]*Warnings:[ \t]*(\d+)"
        r"(?:,[ \t]*Suppressed Errors:[ \t]*(\d+))?"
        r"(?:,[ \t]*Suppressed Warnings:[ \t]*(\d+))?[ \t]*$",
        log, re.M
    ))

    if not summaries:
        raise ValueError("Missing simulator summary")

    for summary in summaries:
        if int(summary.group(1)) or int(summary.group(3) or 0):
            raise ValueError("Simulator errors or suppressed errors")

    fatal_summary = re.search(
        r"^# UVM_FATAL[ \t]*:[ \t]*\d+[ \t]*$",
        log, re.M
    )

    if summaries[-1].start() <= fatal_summary.end():
        raise ValueError("Missing final simulator summary")

    if re.search(
        r"(?im)^[ \t]*(?:#[ \t]*)?\*\*[ \t]+"
        r"(?:Error|Fatal|Failure)\b",
        log
    ):
        raise ValueError("Simulator error or assertion failure")

    return counts["ERROR"], counts["FATAL"]
