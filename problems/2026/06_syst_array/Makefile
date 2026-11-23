include ../03_syst_array/Makefile
.DEFAULT_GOAL := test
AXIL_RTL := $(STREAM_RTL) $(wildcard ../05_syst_array/src/*.sv src/*.sv) \
	$(addprefix ../../../examples/2026/06_axil2reg/src/,axil2reg.sv axil2reg_rd.sv axil2reg_wr.sv)

test:
	@set -e; bin=$$(mktemp); trap 'rm -f "$$bin"' EXIT; \
	iverilog -g2012 -Wall -s sa_axil_tb -o "$$bin" $(AXIL_RTL) sa_axil_tb.sv; \
	vvp "$$bin"

.PHONY: test
