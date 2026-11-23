include ../03_syst_array/Makefile
.DEFAULT_GOAL := test
AXI_RTL := $(STREAM_RTL) $(wildcard src/*.sv)

test:
	@set -e; bin=$$(mktemp); trap 'rm -f "$$bin"' EXIT; \
	iverilog -g2012 -Wall -s sa_axi_tb -o "$$bin" $(AXI_RTL) sa_axi_tb.sv; \
	vvp "$$bin"

.PHONY: test
