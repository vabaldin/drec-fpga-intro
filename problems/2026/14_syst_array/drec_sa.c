#include <linux/bitops.h>
#include <linux/dma-mapping.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/iopoll.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/uaccess.h>

#include "sa_ioctl.h"

#define COMMAND 0x00
#define STATUS  0x04
#define ADDR_A  0x08
#define ADDR_B  0x0c
#define ADDR_C  0x10
#define LOAD_B  1
#define RUN_A   2
#define BUSY    BIT(0)
#define DONE    BIT(1)
#define ERROR   BIT(2)
#define STRIDE  (SA_WORDS * sizeof(__le64))

static DEFINE_MUTEX(sa_lock);
static void __iomem *regs;
static __le64 *buffer;
static dma_addr_t buffer_dma;

static int run_command(u32 cmd)
{
    u32 status;
    int ret;

    writel(cmd, regs + COMMAND);
    ret = readl_poll_timeout(regs + STATUS, status, (status & (BUSY | DONE)) == DONE,
                            10, 100000);
    if (ret)
        return ret;
    return status & ERROR ? -EIO : 0;
}

static long sa_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    struct sa_job job;
    void __user *user = (void __user *)arg;
    int ret;

    if (cmd != SA_MULTIPLY)
        return -ENOTTY;
    if (copy_from_user(&job, user, sizeof(job)))
        return -EFAULT;

    mutex_lock(&sa_lock);
    if (!regs) {
        ret = -ENODEV;
        goto out;
    }
    if (readl(regs + STATUS) & BUSY) {
        ret = -EBUSY;
        goto out;
    }

    for (int i = 0; i < SA_WORDS; i++) {
        buffer[i] = cpu_to_le64(job.a[i]);
        buffer[SA_WORDS + i] = cpu_to_le64(job.b[i]);
    }
    dma_wmb();
    writel(lower_32_bits(buffer_dma), regs + ADDR_A);
    writel(lower_32_bits(buffer_dma + STRIDE), regs + ADDR_B);
    writel(lower_32_bits(buffer_dma + 2 * STRIDE), regs + ADDR_C);
    ret = run_command(LOAD_B);
    if (!ret)
        ret = run_command(RUN_A);
    if (!ret) {
        dma_rmb();
        for (int i = 0; i < SA_WORDS; i++)
            job.c[i] = le64_to_cpu(buffer[2 * SA_WORDS + i]);
    }

out:
    mutex_unlock(&sa_lock);
    if (!ret && copy_to_user(user, &job, sizeof(job)))
        return -EFAULT;
    return ret;
}

static const struct file_operations sa_fops = {
    .owner = THIS_MODULE,
    .unlocked_ioctl = sa_ioctl,
    .compat_ioctl = compat_ptr_ioctl,
};

static struct miscdevice sa_dev = {
    .minor = MISC_DYNAMIC_MINOR,
    .name = "drec-sa",
    .fops = &sa_fops,
    .mode = 0600,
};

static int sa_probe(struct platform_device *pdev)
{
    struct device *dev = &pdev->dev;
    void __iomem *base;
    int ret;

    base = devm_platform_ioremap_resource(pdev, 0);
    if (IS_ERR(base))
        return PTR_ERR(base);
    ret = dma_set_mask_and_coherent(dev, DMA_BIT_MASK(32));
    if (ret)
        return ret;

    mutex_lock(&sa_lock);
    if (regs || (readl(base + STATUS) & BUSY)) {
        ret = -EBUSY;
        goto out;
    }
    buffer = dma_alloc_coherent(dev, 3 * STRIDE, &buffer_dma, GFP_KERNEL);
    if (!buffer) {
        ret = -ENOMEM;
        goto out;
    }
    regs = base;
    ret = misc_register(&sa_dev);
    if (ret) {
        regs = NULL;
        dma_free_coherent(dev, 3 * STRIDE, buffer, buffer_dma);
    }
out:
    mutex_unlock(&sa_lock);
    return ret;
}

static void sa_remove(struct platform_device *pdev)
{
    u32 status;

    misc_deregister(&sa_dev);
    mutex_lock(&sa_lock);
    if (readl_poll_timeout(regs + STATUS, status, !(status & BUSY), 10, 100000))
        dev_err(&pdev->dev, "DMA still active, keeping the buffer allocated\n");
    else
        dma_free_coherent(&pdev->dev, 3 * STRIDE, buffer, buffer_dma);
    regs = NULL;
    mutex_unlock(&sa_lock);
}

static const struct of_device_id sa_match[] = {
    { .compatible = "drec,systolic-array" },
    { }
};
MODULE_DEVICE_TABLE(of, sa_match);

static struct platform_driver sa_driver = {
    .probe = sa_probe,
    .remove = sa_remove,
    .driver = {
        .name = "drec-sa",
        .of_match_table = sa_match,
    },
};
module_platform_driver(sa_driver);
MODULE_DESCRIPTION("Zynq systolic array matrix accelerator");
MODULE_LICENSE("GPL");
