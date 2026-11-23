#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/vmalloc.h>

#include "alloc_ioctl.h"

static long probe_alloc(struct file *file, unsigned int cmd, unsigned long arg)
{
    __u64 size;
    void *memory;

    if (cmd != DREC_KMALLOC && cmd != DREC_VMALLOC)
        return -ENOTTY;
    if (copy_from_user(&size, (void __user *)arg, sizeof(size)))
        return -EFAULT;
    if (!size)
        return -EINVAL;
    if (size > SIZE_MAX)
        return -ENOMEM;

    if (cmd == DREC_KMALLOC) {
        if (size > KMALLOC_MAX_SIZE)
            return -ENOMEM;
        memory = kmalloc(size, GFP_KERNEL | __GFP_NOWARN | __GFP_NORETRY);
        if (!memory)
            return -ENOMEM;
        kfree(memory);
    } else {
        memory = __vmalloc(size, GFP_KERNEL | __GFP_NOWARN | __GFP_NORETRY);
        if (!memory)
            return -ENOMEM;
        vfree(memory);
    }

    return 0;
}

static const struct file_operations probe_fops = {
    .owner = THIS_MODULE,
    .unlocked_ioctl = probe_alloc,
    .compat_ioctl = compat_ptr_ioctl,
};

static struct miscdevice probe_dev = {
    .minor = MISC_DYNAMIC_MINOR,
    .name = "alloc-probe",
    .fops = &probe_fops,
    .mode = 0600,
};

static int __init alloc_probe_init(void)
{
    return misc_register(&probe_dev);
}

static void __exit alloc_probe_exit(void)
{
    misc_deregister(&probe_dev);
}

module_init(alloc_probe_init);
module_exit(alloc_probe_exit);
MODULE_DESCRIPTION("kmalloc and vmalloc allocation probe");
MODULE_LICENSE("GPL");
