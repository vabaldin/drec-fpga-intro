## Задание

1. Запустить Linux в QEMU с устройством `mul-dev`
2. Получить доступ к регистрам `mul-dev` через BusyBox `devmem`
Передайте ядро ARMv7 с поддержкой PL011, initramfs, devtmpfs и `/dev/mem`,
а также статический BusyBox с апплетом `devmem`.

```sh
make test QEMU=/путь/к/qemu-system-arm KERNEL=/путь/к/zImage BUSYBOX=/путь/к/busybox
```

QEMU должен содержать [патч из задания 07a](../07_qemu_muldev/mul-dev.patch).
Тест загружает Linux, записывает 7 и 9 в регистры устройства и сверяет результат
63, прочитанный через `devmem`.
