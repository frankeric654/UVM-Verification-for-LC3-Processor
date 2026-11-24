#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "$repo"

exec python3 - "$repo" "$@" <<'PY'
from pathlib import Path, PurePosixPath
import argparse
import json
import os
import subprocess
import tempfile
import zipfile

ap = argparse.ArgumentParser()
ap.add_argument("repo", type=Path)

mode = ap.add_mutually_exclusive_group(required=True)
mode.add_argument("--check", action="store_true")
mode.add_argument("--check-index", action="store_true")
mode.add_argument("--final", action="store_true")

ap.add_argument("output", nargs="?",
                default=str(Path.home() / "748/p3_submission"))

args = ap.parse_args()

repo = args.repo.resolve()
output = Path(args.output).expanduser().resolve()

def git(*argv):
    return subprocess.check_output(
        ["git", *argv],
        cwd=repo,
        text=True
    ).strip()

def require(condition, message):
    if not condition:
        raise SystemExit(message)

if args.check_index:
    require(
        not git("diff", "--name-only"),
        "Unstaged tracked changes remain"
    )
    require(
        not git("ls-files", "--others", "--exclude-standard"),
        "Untracked files remain"
    )
    revision = git("write-tree")
else:
    require(
        not git("status", "--porcelain"),
        "Commit intended changes before packaging"
    )
    revision = git("rev-parse", "HEAD")

output.mkdir(parents=True, exist_ok=True)

stage = Path(tempfile.mkdtemp(
    prefix=".p3-package.",
    dir=output
))

archive = stage / "source.zip"

subprocess.run(
    ["git", "archive", "--format=zip",
     "-o", str(archive), revision],
    cwd=repo,
    check=True
)

with zipfile.ZipFile(archive) as z:
    names = set(z.namelist())

    for name in names:
        p = PurePosixPath(name)

        require(
            not p.is_absolute()
            and not any(part in {
                ".git", "..", "work", "build", "__pycache__"
            } for part in p.parts),
            "Unexpected archive path: " + name
        )

        require(
            p.suffix.lower() not in {
                ".ucdb", ".wlf", ".pyc", ".o",
                ".so", ".dll", ".vcd", ".log"
            },
            "Unexpected generated file: " + name
        )

    required = {
        "project_benches/lc3/sim/Makefile",
        "project_benches/lc3/sim/run.py",
        "project_benches/lc3/sim/regress.sh",
        "project_benches/lc3/sim/sim_checks.py",
        "project_benches/lc3/sim/sim_paths.py",
        "scripts/package_p3.sh"
    }

    require(required <= names, "Missing required source files")

    rtl_files = {
        "Fetch.v", "Decode_Pipelined.v", "Execute.v",
        "Mem_Access.v", "WriteBack.v",
        "Controller_Pipeline.v", "TopLevelLC3.v",
        "data_defs.v"
    }

    canonical = all(
        "project_benches/lc3/rtl/" + f in names
        for f in rtl_files
    )

    legacy = all(
        "project_benches/project3/rtl/" + f in names
        for f in rtl_files
    )

    require(canonical or legacy, "Incomplete RTL sources")
    require(z.testzip() is None, "Archive integrity failure")

print("SOURCE ARCHIVE PRECHECK: PASS")
print("Source revision:", revision)
print("Workspace:", stage)

if not args.final:
    print("PRECHECK ONLY - NOT A SUBMISSION ARCHIVE")
    raise SystemExit(0)

required_final = {
    "verification_ip/interface_packages/dmem_pkg/dmem_pkg.sv",
    "project_benches/lc3/tb/sequences/lc3_sequence_pkg/lc3_sequence_pkg.sv"
}

require(
    required_final <= names,
    "FINAL PACKAGING BLOCKED: DMEM or top-level sequence missing"
)

require(
    canonical,
    "FINAL PACKAGING BLOCKED: canonical RTL directory missing"
)

final = output / "group06_p3.zip"

require(
    not final.exists(),
    "Refusing to overwrite existing submission"
)

src = stage / "src"
src.mkdir()

tar = stage / "source.tar"

subprocess.run(
    ["git", "archive", "--format=tar",
     "-o", str(tar), revision],
    cwd=repo,
    check=True
)

subprocess.run(
    ["tar", "-xf", str(tar), "-C", str(src)],
    check=True
)

env = os.environ.copy()

for key in (
    "EXTRA_SV_SOURCES",
    "EXTRA_VLOG_ARGS",
    "EXTRA_VOPT_TOPS",
    "LC3_RTL_DIR"
):
    env.pop(key, None)

result_root = stage / "results"
regress = src / "project_benches/lc3/sim/regress.sh"

print("===== FRESH STRICT REGRESSION =====", flush=True)

with (stage / "strict.log").open("w") as log:
    result = subprocess.run(
        [str(regress), "--out-root", str(result_root)],
        cwd=src,
        env=env,
        stdout=log,
        stderr=subprocess.STDOUT
    )

require(
    result.returncode == 0,
    "FINAL PACKAGING BLOCKED: strict regression failed; "
    + str(stage / "strict.log")
)

runs = list(result_root.glob("regress.*"))

require(len(runs) == 1, "Unexpected regression output count")

run = runs[0]
status_file = run / "regression_status.json"
status = json.loads(status_file.read_text())

require(
    status["mode"] == "STRICT"
    and status["status"] == "PASS"
    and status["coverage_scope"] == "ALL_COMPLETED_TESTS",
    "Strict regression did not pass"
)

artifacts = {
    "merged.ucdb": run / "merged.ucdb",
    "coverage_summary.txt": run / "coverage_summary.txt",
    "regression_status.json": status_file
}

require(status["tests"], "No completed tests")

for label, info in status["tests"].items():
    require(Path(label).name == label, "Invalid test label")

    require(
        info["status"] == "PASS"
        and info["uvm_errors"] == 0
        and info["uvm_fatals"] == 0
        and info["ucdb_included"],
        "Failed test: " + label
    )

    artifacts[label + "_simulation.log"] = (
        run / label / "simulation.log"
    )

for name, path in artifacts.items():
    require(
        path.is_file() and path.stat().st_size > 0,
        "Missing artifact: " + name
    )

prefix = "project_benches/lc3/sim/results/"

with zipfile.ZipFile(
    archive, "a", compression=zipfile.ZIP_DEFLATED
) as z:
    for name, path in artifacts.items():
        z.write(path, prefix + name)

    z.writestr(prefix + "source_commit.txt", revision + "\n")

with zipfile.ZipFile(archive) as z:
    databases = [
        n for n in z.namelist()
        if n.lower().endswith(".ucdb")
    ]

    require(
        databases == [prefix + "merged.ucdb"],
        "Unexpected UCDB contents"
    )

    require(z.testzip() is None, "Final archive integrity failure")

os.link(archive, final)

print("SUBMISSION ARTIFACT VALIDATION: PASS")
print("FINAL SUBMISSION ARCHIVE:", final)
PY
