SHELL := /bin/bash
.DEFAULT_GOAL := build

TOOLCHAIN ?= .toolchain/mapanare
BUILD_DIR ?= build
BACKEND ?= native
CLANG ?= clang
PYTHON ?= python3

ifeq ($(BACKEND),native)
COMPILER := $(TOOLCHAIN)/mnc
else ifeq ($(BACKEND),bootstrap)
COMPILER := $(TOOLCHAIN)/mapanare
else
$(error BACKEND must be native or bootstrap)
endif

.PHONY: setup build run test
setup:
	bash scripts/setup-toolchain.sh

build:
	@test -x "$(COMPILER)" || { echo 'Run make setup first.' >&2; exit 1; }
	mkdir -p "$(BUILD_DIR)"
	"$(COMPILER)" emit-llvm src/main.mn -o "$(BUILD_DIR)/cascabel.ll"
	$(CLANG) -O2 "$(BUILD_DIR)/cascabel.ll" "$(TOOLCHAIN)/_internal/runtime/native/mapanare_core.c" -o "$(BUILD_DIR)/cascabel"

run: build
	"$(BUILD_DIR)/cascabel"

test:
	$(PYTHON) -m pytest tests/ -q
