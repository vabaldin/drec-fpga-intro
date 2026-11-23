#!/bin/sh
set -eu

for pattern in 0 5 10 15 0; do
    busybox devmem 0x43c00000 32 "$pattern"
    value=$(busybox devmem 0x43c00000 32)
    [ "$((value))" -eq "$pattern" ]
    [ "$pattern" -eq 0 ] || sleep 1
done
echo 'PASS AXI LED'
