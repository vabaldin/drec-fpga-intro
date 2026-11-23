#ifndef DREC_SA_IOCTL_H
#define DREC_SA_IOCTL_H

#include <linux/ioctl.h>
#include <linux/types.h>

#define SA_SIZE 4
#define SA_WORDS (SA_SIZE * SA_SIZE)

struct sa_job {
    __u16 a[SA_WORDS];
    __u16 b[SA_WORDS];
    __u64 c[SA_WORDS];
};

#define SA_MULTIPLY _IOWR('s', 1, struct sa_job)

#endif
