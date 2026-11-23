RTL := src/axis_fifo.sv ../03_syst_array/src/stream_fifo.sv

test:
	@set -e; bin=$$(mktemp); trap 'rm -f "$$bin"' EXIT; \
	for depth in 1 3; do \
	    iverilog -g2012 -Wall -s axis_fifo_tb -P axis_fifo_tb.DEPTH=$$depth \
	        -o "$$bin" $(RTL) src/axis_fifo_tb.sv; \
	    vvp "$$bin"; \
	done

.PHONY: test
