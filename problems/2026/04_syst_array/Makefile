include ../03_syst_array/Makefile
.DEFAULT_GOAL := test

test:
	@set -e; bin=$$(mktemp); trap 'rm -f "$$bin"' EXIT; \
	for size in 1 4; do \
	    iverilog -g2012 -Wall -s sa_stream_tb -P sa_stream_tb.SIZE=$$size \
	        -P sa_stream_tb.DEPTH=$$((size / 4 + 1)) -o "$$bin" $(STREAM_RTL) sa_stream_tb.sv; \
	    vvp "$$bin"; \
	done

.PHONY: test
