QEMU ?= qemu-system-arm

test:
	@test -f "$(KERNEL)" && test -f "$(BUSYBOX)"
	@set -e; tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
	mkdir -p "$$tmp/root/bin" "$$tmp/root/dev"; \
	cp "$(BUSYBOX)" "$$tmp/root/bin/busybox"; \
	cp init "$$tmp/root/init"; \
	chmod +x "$$tmp/root/init" "$$tmp/root/bin/busybox"; \
	(cd "$$tmp/root" && find . | cpio -o -H newc > "$$tmp/initramfs"); \
	$(QEMU) -M virt -cpu cortex-a15 -m 256 -nographic -monitor none \
	    -no-reboot -kernel "$(KERNEL)" -initrd "$$tmp/initramfs" \
	    -append 'console=ttyAMA0 rdinit=/init' > "$$tmp/console" 2>&1 || \
	    { cat "$$tmp/console"; exit 1; }; \
	cat "$$tmp/console"; grep -q '^PASS Linux mul-dev' "$$tmp/console"

.PHONY: test
