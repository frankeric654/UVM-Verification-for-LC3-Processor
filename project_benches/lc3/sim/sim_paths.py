"""Shared LC3 toolchain discovery and build extension helpers."""

from pathlib import Path
import os
import shlex
import shutil


def env_words(name):
    try:
        return shlex.split(os.getenv(name, ""))
    except ValueError as exc:
        raise ValueError(f"Invalid {name}: {exc}") from exc


def extra_sources():
    return [
        Path(word).expanduser().resolve()
        for word in env_words("EXTRA_SV_SOURCES")
    ]


def resolve_tools(questa=None, uvmf=None):
    def valid_questa(path):
        return (
            path.is_dir()
            and all(
                (path / "bin" / name).is_file()
                for name in ("vlib", "vlog", "vopt", "vsim", "vcover")
            )
            and (path / "uvm-1.2").exists()
        )

    if questa:
        q = Path(questa).expanduser().resolve()
    else:
        executable = shutil.which("vsim")

        if not executable:
            raise ValueError(
                "QUESTA_HOME is unset and vsim is not on PATH"
            )

        executable = Path(executable).absolute()

        candidates = [
            executable.parent.parent,
            executable.resolve().parent.parent,
        ]

        q = next(
            (p.resolve() for p in candidates if valid_questa(p)),
            None
        )

        if q is None:
            raise ValueError(
                "Cannot discover Questa installation; set QUESTA_HOME"
            )

    if not valid_questa(q):
        raise ValueError(f"Invalid Questa installation: {q}")

    def valid_uvmf(path):
        base = path / "uvmf_base_pkg"
        return all(
            (base / name).is_file()
            for name in (
                "uvmf_base_pkg.sv",
                "uvmf_base_pkg_hdl.sv"
            )
        )

    if uvmf:
        u = Path(uvmf).expanduser().resolve()
    else:
        directory = q / "examples/UVM_Framework"

        candidates = sorted(
            p for p in directory.glob("UVMF_*")
            if valid_uvmf(p)
        )

        if len(candidates) != 1:
            raise ValueError(
                "Set UVMF_HOME explicitly; discovered: "
                + ", ".join(map(str, candidates))
            )

        u = candidates[0].resolve()

    if not valid_uvmf(u):
        raise ValueError(f"Invalid UVMF installation: {u}")

    return q, u


def resolve_rtl(repo, explicit=None):
    if explicit:
        path = Path(explicit).expanduser().resolve()
    else:
        preferred = repo / "project_benches/lc3/rtl"
        legacy = repo / "project_benches/project3/rtl"

        path = preferred if preferred.is_dir() else legacy

    if not path.is_dir():
        raise ValueError(f"RTL directory does not exist: {path}")

    return path.resolve()
