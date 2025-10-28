#include <stdio.h>
#include <stdint.h>

// =====================================================
// clz
// =====================================================
uint32_t clz32(uint32_t x) {
    if (x == 0) return 32;
    uint32_t n = 0;
    uint32_t step = 16;
    while (step) {
        uint32_t shifted = x >> step;
        if (shifted == 0) {
            n += step;
        } else {
            x = shifted;
        }
        step >>= 1;
    }
    return n;
}


int isPowerOfTwo_clz(uint32_t x) {
    if (x == 0) return 0;
    uint32_t c1 = clz32(x);
    uint32_t c2 = clz32(x - 1);
    return (c1 != c2);
}

// =====================================================
// test main
// =====================================================
int main(void) {
    uint32_t cases_in[]  = {0, 1, 2, 3, 4, 5, 8, 16, 31, 32, 1024, 1025};
    uint32_t cases_exp[] = {0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0};
    int n = sizeof(cases_in) / sizeof(cases_in[0]);

    int pass_count = 0;

    printf("CLZ Version Test\n");

    for (int i = 0; i < n; i++) {
        uint32_t x = cases_in[i];
        int got = isPowerOfTwo_clz(x);
        int exp = cases_exp[i];

        if (got == exp) {
            printf("PASS %u -> %d\n", x, got);
            pass_count++;
        } else {
            printf("FAIL %u exp=%d got=%d\n", x, exp, got);
        }
    }

    printf("PASS %d/%d\n", pass_count, n);
    return 0;
}
