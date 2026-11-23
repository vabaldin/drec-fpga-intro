obj-m := drec_led.o
KDIR ?= /lib/modules/$(shell uname -r)/build

all: module led-overlay.dtbo

module:
	$(MAKE) -C "$(KDIR)" M="$(CURDIR)" modules

led-overlay.dtbo: led-overlay.dts
	dtc -@ -I dts -O dtb -o $@ $<

clean:
	$(MAKE) -C "$(KDIR)" M="$(CURDIR)" clean
	rm -f led-overlay.dtbo

.PHONY: all module clean
