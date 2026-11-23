#ifndef DREC_ALLOC_IOCTL_H
#define DREC_ALLOC_IOCTL_H

#include <linux/ioctl.h>
#include <linux/types.h>

#define DREC_KMALLOC _IOW('a', 1, __u64)
#define DREC_VMALLOC _IOW('a', 2, __u64)

#endif
