#include <stdint.h>

#define MUL ((volatile uint32_t *)0x09008000u)
#define UART (*(volatile uint8_t *)0x09000000u)

static void finish(unsigned status)
{
    const char *msg = status ? "FAIL mul-dev\r\n" : "PASS mul-dev\r\n";
    uint32_t args[] = {0x20026, status};
    register uint32_t r0 __asm__("r0") = 0x20;
    register uint32_t *r1 __asm__("r1") = args;

    while (*msg)
        UART = *msg++;
    __asm__ volatile("svc #0x123456" : : "r"(r0), "r"(r1) : "memory");
    for (;;)
        ;
}

void entry(void)
{
    if (MUL[0] || MUL[1] || MUL[2])
        finish(1);
    MUL[0] = 7;
    MUL[1] = 9;
    MUL[2] = 1;
    if (MUL[0] != 7 || MUL[1] != 9 || MUL[2] != 63)
        finish(1);
    MUL[0] = UINT32_MAX;
    MUL[1] = 2;
    finish(MUL[2] != UINT32_MAX - 1);
}
