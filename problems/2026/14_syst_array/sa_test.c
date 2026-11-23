#include <fcntl.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "sa_ioctl.h"

int main(void)
{
    struct sa_job job = { 0 };
    int fd = open("/dev/drec-sa", O_RDWR);

    if (fd < 0) {
        perror("/dev/drec-sa");
        return 1;
    }
    for (int n = 0; n < SA_WORDS; n++) {
        job.a[n] = 65535 - n * 773;
        job.b[n] = 65535 - n * 1579;
    }
    if (ioctl(fd, SA_MULTIPLY, &job) < 0) {
        perror("SA_MULTIPLY");
        close(fd);
        return 1;
    }
    close(fd);

    for (int row = 0; row < SA_SIZE; row++) {
        for (int col = 0; col < SA_SIZE; col++) {
            __u64 expected = 0;

            for (int k = 0; k < SA_SIZE; k++)
                expected += (__u64)job.a[row * SA_SIZE + k] * job.b[k * SA_SIZE + col];
            if (job.c[row * SA_SIZE + col] != expected) {
                fprintf(stderr, "Incorrect C[%d,%d]\n", row, col);
                return 1;
            }
        }
    }
    puts("PASS systolic array");
    return 0;
}
