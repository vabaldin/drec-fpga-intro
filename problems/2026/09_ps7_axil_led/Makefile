RTL := axil_led.v $(addprefix ../../../examples/2026/06_axil2reg/src/,axil2reg.sv axil2reg_rd.sv axil2reg_wr.sv)

test:
	@set -e; bin=$$(mktemp); trap 'rm -f "$$bin"' EXIT; \
	iverilog -g2012 -Wall -s axil_led_tb -o "$$bin" $(RTL) axil_led_tb.sv; \
	vvp "$$bin"

bitstream:
	vivado -mode batch -source project.tcl

.PHONY: test bitstream
