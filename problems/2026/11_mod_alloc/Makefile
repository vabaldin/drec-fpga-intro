obj-m := alloc_probe.o
KDIR ?= /lib/modules/$(shell uname -r)/build

all: module measure

module:
	$(MAKE) -C "$(KDIR)" M="$(CURDIR)" modules

measure: measure.c alloc_ioctl.h
	$(CC) $(CFLAGS) -Wall -Wextra $(LDFLAGS) -o $@ measure.c

clean:
	$(MAKE) -C "$(KDIR)" M="$(CURDIR)" clean
	rm -f measure

.PHONY: all module clean
