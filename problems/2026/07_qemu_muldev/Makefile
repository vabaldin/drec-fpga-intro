ARM_CC ?= arm-none-eabi-gcc
ARM_LD ?= arm-none-eabi-ld
QEMU ?= qemu-system-arm
EXAMPLE := ../../../examples/2026/07_qemu_incdev

test:
	@set -e; tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
	cd "$$tmp"; \
	$(ARM_CC) -mcpu=cortex-a15 -marm -c "$(CURDIR)/$(EXAMPLE)/start.s" -o start.o; \
	$(ARM_CC) -mcpu=cortex-a15 -marm -ffreestanding -fno-stack-protector \
	    -fno-pic -O2 -Wall -Wextra -c "$(CURDIR)/mul_test.c" -o mul_test.o; \
	$(ARM_LD) -T "$(CURDIR)/virt.ld" start.o mul_test.o -o mul_test.elf; \
	$(QEMU) -M virt -cpu cortex-a15 -nographic -monitor none \
	    -semihosting-config enable=on,target=native -kernel mul_test.elf

.PHONY: test
