#!/bin/sh
set -eu

for value in 0 5 a f 0; do
    printf '%s\n' "$value" > /dev/drec-led
    [ "$(cat /dev/drec-led)" = "$value" ]
    [ "$value" = 0 ] || sleep 1
done
if (printf '10\n' > /dev/drec-led) 2>/dev/null; then
    exit 1
fi
echo 'PASS drec-led'
