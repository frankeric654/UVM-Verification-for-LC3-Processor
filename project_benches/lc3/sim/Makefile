# Unified LC3 verification build interface.
# run.py remains the single source of truth for compilation.

.DEFAULT_GOAL := help

SIM_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SIM_DIR)/../../..)

PYTHON ?= python3
RTL_DIR ?= $(if $(LC3_RTL_DIR),$(LC3_RTL_DIR),$(ROOT)/project_benches/project3/rtl)
OUT_ROOT ?= $(SIM_DIR)/build

SEED ?= 1
SEEDS ?= 1 2 3
CYCLES ?= 300

RUN = "$(PYTHON)" "$(SIM_DIR)/run.py" \
      --rtl-dir "$(RTL_DIR)" \
      --uvmf-home "$(UVMF_HOME)" \
      --questa-home "$(QUESTA_HOME)"

.PHONY: help compile smoke regress

help: ; @printf '%s\n' \
    "LC3 Verification Build" \
    "make compile                 Compile all LC3 sources" \
    "make smoke                   Run one smoke test" \
    "make smoke SEED=2            Select a simulation seed" \
    "make regress                 Run seeds 1, 2, 3" \
    "make regress SEEDS='1 2 3'   Select regression seeds" \
    "make smoke CYCLES=1000       Select simulation length"

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

regress: ; @set -eu; \
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
