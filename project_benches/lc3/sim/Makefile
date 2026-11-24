# Unified LC3 verification build interface.
# run.py remains the single source of truth for compilation.

.DEFAULT_GOAL := help

SIM_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SIM_DIR)/../../..)

PYTHON ?= python3
DEFAULT_RTL := $(if $(wildcard $(ROOT)/project_benches/lc3/rtl),$(ROOT)/project_benches/lc3/rtl,$(ROOT)/project_benches/project3/rtl)
RTL_DIR ?= $(if $(LC3_RTL_DIR),$(LC3_RTL_DIR),$(DEFAULT_RTL))

export EXTRA_SV_SOURCES EXTRA_VLOG_ARGS EXTRA_VOPT_TOPS
OUT_ROOT ?= $(SIM_DIR)/build

SEED ?= 1
SEEDS ?= 1 2 3
CYCLES ?= 300
TOOL_TIMEOUT ?= 300

RUN = "$(PYTHON)" "$(SIM_DIR)/run.py" \
      --rtl-dir "$(RTL_DIR)" \
      $(if $(strip $(UVMF_HOME)),--uvmf-home "$(UVMF_HOME)") \
      $(if $(strip $(QUESTA_HOME)),--questa-home "$(QUESTA_HOME)") --timeout "$(TOOL_TIMEOUT)"

.PHONY: help compile smoke smoke-regress regress characterize

help: ; @printf '%s\n' \
    "LC3 Verification Build" \
    "make compile          Compile all LC3 sources" \
    "make smoke            Strict single-seed smoke" \
    "make smoke-regress    Strict multi-seed smoke" \
    "make baseline         Known-issue regression gate" \
    "make regress          Strict full coverage regression" \
    "make characterize     Experimental full regression" \
    "Parameters: SEED, SEEDS, CYCLES, TOOL_TIMEOUT, RTL_DIR, OUT_ROOT"


compile: ; @set -eu; \
    mkdir -p "$(OUT_ROOT)"; \
    out=$$(mktemp -d "$(OUT_ROOT)/compile.XXXXXX"); \
    echo "Build directory: $$out"; \
    $(RUN) --out "$$out" --compile-only

smoke: ; @set -eu; \
    mkdir -p "$(OUT_ROOT)"; \
    out=$$(mktemp -d "$(OUT_ROOT)/smoke.XXXXXX"); \
    echo "Run directory: $$out"; \
    $(RUN) --out "$$out" --seed "$(SEED)" --cycles "$(CYCLES)"

smoke-regress: ; @set -eu; \
    test -n "$(strip $(SEEDS))"; \
    mkdir -p "$(OUT_ROOT)"; \
    root=$$(mktemp -d "$(OUT_ROOT)/regress.XXXXXX"); \
    echo "Regression directory: $$root"; \
    rc=0; \
    for seed in $(SEEDS); do \
        echo "===== SEED $$seed ====="; \
        if $(RUN) --out "$$root/seed$$seed" \
            --seed "$$seed" --cycles "$(CYCLES)"; then \
            echo "SEED $$seed: PASS"; \
        else \
            echo "SEED $$seed: FAIL"; \
            rc=1; \
        fi; \
    done; \
    echo "Regression logs: $$root"; \
    exit $$rc

# Temporary known-issue baseline. Strict regress remains unchanged.
.PHONY: baseline

baseline: ; @set -eu; \
    test "$(CYCLES)" = "300" || { echo "Baseline requires 300 cycles"; exit 1; }; \
    test -n "$(strip $(SEEDS))"; \
    mkdir -p "$(OUT_ROOT)"; \
    root=$$(mktemp -d "$(OUT_ROOT)/baseline.XXXXXX"); \
    failed=0; \
    for seed in $(SEEDS); do \
        echo "===== BASELINE SEED $$seed ====="; \
        out="$$root/seed$$seed"; \
        rc=0; \
        $(RUN) --out "$$out" --seed "$$seed" --cycles 300 || rc=$$?; \
        "$(PYTHON)" "$(SIM_DIR)/check_baseline.py" "$$out" "$$rc" || failed=1; \
    done; \
    echo "Baseline logs: $$root"; \
    exit $$failed

# Full regression has one implementation: regress.sh.
COMPETITION = LC3_RTL_DIR="$(RTL_DIR)" LC3_PYTHON="$(PYTHON)" UVMF_HOME="$(UVMF_HOME)" QUESTA_HOME="$(QUESTA_HOME)" "$(SIM_DIR)/regress.sh" --seed "$(SEED)" --timeout "$(TOOL_TIMEOUT)" --out-root "$(OUT_ROOT)"

regress: ; @$(COMPETITION)

characterize: ; @$(COMPETITION) --characterize
