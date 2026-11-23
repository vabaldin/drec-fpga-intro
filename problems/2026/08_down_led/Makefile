test:
	@set -e; bin=$$(mktemp); trap 'rm -f "$$bin"' EXIT; \
	iverilog -g2012 -Wall -s down_cnt_tb -o "$$bin" src/*.sv; \
	vvp "$$bin"; \
	iverilog -g2012 -Wall -s fpga_top -tnull src/down_cnt.sv src/fpga_top.v

bitstream:
	vivado -mode batch -source project.tcl

.PHONY: test bitstream
