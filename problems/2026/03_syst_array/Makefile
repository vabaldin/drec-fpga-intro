STREAM_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
CORE := $(wildcard $(STREAM_DIR)../02_syst_array/src/*.sv)
STREAM_RTL := $(filter-out %_tb.sv,$(CORE)) $(wildcard $(STREAM_DIR)src/*.sv)

lint:
	verilator --lint-only --top-module sa_stream $(STREAM_RTL)

.PHONY: lint
