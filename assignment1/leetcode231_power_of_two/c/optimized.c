#include <stdio.h>
#include <stdint.h>

// =====================================================
// optimized: x & (x-1)
// =====================================================
int isPowerOfTwo_fast(uint32_t x) {
    if (x == 0u) return 0;
    return ((x & (x - 1u)) == 0u);
}

// =====================================================
// test main
// =====================================================
int main(void) {
    uint32_t cases_in[]  = {0, 1, 2, 3, 4, 5, 8, 16, 31, 32, 1024, 1025};
    uint32_t cases_exp[] = {0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0};
    int n = sizeof(cases_in) / sizeof(cases_in[0]);

    int pass_count = 0;
    printf("Optimized Version Test\n");

    for (int i = 0; i < n; i++) {
        uint32_t x = cases_in[i];
        int got = isPowerOfTwo_fast(x);
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