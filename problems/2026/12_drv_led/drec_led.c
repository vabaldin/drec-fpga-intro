#include <linux/fs.h>
#include <linux/io.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/of.h>
#include <linux/platform_device.h>

static DEFINE_MUTEX(led_lock);
static void __iomem *led_reg;

static ssize_t led_read(struct file *file, char __user *buf, size_t count, loff_t *pos)
{
    char value[3];
    int len;

    mutex_lock(&led_lock);
    if (!led_reg) {
        mutex_unlock(&led_lock);
        return -ENODEV;
    }
    len = scnprintf(value, sizeof(value), "%x\n", readl(led_reg) & 0xf);
    mutex_unlock(&led_lock);
    return simple_read_from_buffer(buf, count, pos, value, len);
}

static ssize_t led_write(struct file *file, const char __user *buf, size_t count, loff_t *pos)
{
    u8 value;
    int ret;

    ret = kstrtou8_from_user(buf, count, 16, &value);
    if (ret)
        return ret;
    if (value > 0xf)
        return -EINVAL;

    mutex_lock(&led_lock);
    if (!led_reg) {
        mutex_unlock(&led_lock);
        return -ENODEV;
    }
    writel(value, led_reg);
    mutex_unlock(&led_lock);
    return count;
}

static const struct file_operations led_fops = {
    .owner = THIS_MODULE,
    .read = led_read,
    .write = led_write,
};

static struct miscdevice led_dev = {
    .minor = MISC_DYNAMIC_MINOR,
    .name = "drec-led",
    .fops = &led_fops,
    .mode = 0600,
};

static int led_probe(struct platform_device *pdev)
{
    void __iomem *base;
    int ret = -EBUSY;

    base = devm_platform_ioremap_resource(pdev, 0);
    if (IS_ERR(base))
        return PTR_ERR(base);

    mutex_lock(&led_lock);
    if (!led_reg) {
        led_reg = base;
        ret = misc_register(&led_dev);
        if (ret)
            led_reg = NULL;
    }
    mutex_unlock(&led_lock);
    return ret;
}

static void led_remove(struct platform_device *pdev)
{
    misc_deregister(&led_dev);
    mutex_lock(&led_lock);
    led_reg = NULL;
    mutex_unlock(&led_lock);
}

static const struct of_device_id led_match[] = {
    { .compatible = "drec,axil-led" },
    { }
};
MODULE_DEVICE_TABLE(of, led_match);

static struct platform_driver led_driver = {
    .probe = led_probe,
    .remove = led_remove,
    .driver = {
        .name = "drec-led",
        .of_match_table = led_match,
    },
};
module_platform_driver(led_driver);
MODULE_DESCRIPTION("AXI Lite LED character device");
MODULE_LICENSE("GPL");
