#include <stdio.h>
#include <stdint.h>

static inline unsigned clz(uint32_t x)
{
    int n = 32, c = 16;
    do {
        uint32_t y = x >> c;
        if (y) {
            n -= c;
            x = y;
        }
        c >>= 1;
    } while (c);
    return n - x;
}

// ------------------------------------------------------
// Compute Next Power of Two using CLZ (32-bit)
// ------------------------------------------------------
static inline uint32_t next_power_of_two(uint32_t x)
{
    if (x == 0u) return 1u;
    unsigned lz = clz(x - 1u);              // clz(x-1)
    return 1u << (32u - lz);                // 1 << (32 - clz(x-1))
}

int main(void)
{
    const uint32_t in[]  = {0,1,2,3,5,9,17,33};
    const uint32_t exp[] = {1,1,2,4,8,16,32,64};
    const int N = (int)(sizeof(in)/sizeof(in[0]));

    int pass = 0;
    puts("=== Next Power of Two ===");
    for (int i = 0; i < N; ++i) {
        uint32_t got = next_power_of_two(in[i]);
        if (got == exp[i]) {
            printf("PASS %u -> %u\n", in[i], got);
            ++pass;
        } else {
            printf("FAIL %u exp=%u got=%u\n", in[i], exp[i], got);
        }
    }
    printf("PASS %d/%d\n", pass, N);
    return 0;
}
