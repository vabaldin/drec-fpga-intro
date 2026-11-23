KDIR ?= /lib/modules/$(shell uname -r)/build
include ../03_syst_array/Makefile
.DEFAULT_GOAL := all
RTL := $(STREAM_RTL) $(wildcard ../05_syst_array/src/*.sv ../06_syst_array/src/*.sv) \
	$(addprefix ../../../examples/2026/06_axil2reg/src/,axil2reg.sv axil2reg_rd.sv axil2reg_wr.sv)

all: module sa_test sa-overlay.dtbo

module:
	$(MAKE) -C "$(KDIR)" M="$(CURDIR)" modules

sa_test: sa_test.c sa_ioctl.h
	$(CC) $(CFLAGS) -Wall -Wextra $(LDFLAGS) -o $@ sa_test.c

sa-overlay.dtbo: sa-overlay.dts
	dtc -@ -I dts -O dtb -o $@ $<

bitstream:
	vivado -mode batch -source project.tcl

test:
	iverilog -g2012 -Wall -s sa_zynq -tnull $(RTL) sa_zynq.v
	$(MAKE) -C ../05_syst_array test
	$(MAKE) -C ../06_syst_array test

clean:
	$(MAKE) -C "$(KDIR)" M="$(CURDIR)" clean
	rm -f sa_test sa-overlay.dtbo

.PHONY: all module bitstream test clean
