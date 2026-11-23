#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "alloc_ioctl.h"

static void measure(int fd, unsigned long cmd, const char *name, __u64 limit)
{
    __u64 low = 0, high = limit;

    while (low < high) {
        __u64 size = low + (high - low) / 2 + 1;

        if (ioctl(fd, cmd, &size) == 0)
            low = size;
        else if (errno == ENOMEM)
            high = size - 1;
        else {
            perror(name);
            exit(1);
        }
    }
    printf("%s: %s%llu bytes\n", name, low == limit ? "at least " : "", (unsigned long long)low);
}

int main(int argc, char **argv)
{
    char *end;
    __u64 limit;
    int fd;

    if (argc != 2 || argv[1][0] < '0' || argv[1][0] > '9') {
        fprintf(stderr, "Usage: %s MAX_BYTES\n", argv[0]);
        return 2;
    }
    errno = 0;
    limit = strtoull(argv[1], &end, 10);
    if (errno || *end || !limit) {
        fprintf(stderr, "Invalid MAX_BYTES\n");
        return 2;
    }

    fd = open("/dev/alloc-probe", O_RDWR);
    if (fd < 0) {
        perror("/dev/alloc-probe");
        return 1;
    }
    measure(fd, DREC_KMALLOC, "kmalloc", limit);
    measure(fd, DREC_VMALLOC, "vmalloc", limit);
    close(fd);
    return 0;
}
