#include <stdio.h>
#include <stdint.h>

// =====================================================
// Baseline shift to div
// =====================================================
int isPowerOfTwo_baseline(uint32_t x) {
    if (x == 0u) return 0;          // 0 不是 2 的冪
    while ((x & 1u) == 0u) {        // 持續右移直到變成奇數
        x >>= 1;
    }
    return x == 1u;                 // 若最後剩 1，代表原本是 2 的冪
}

// =====================================================
// test main
// =====================================================
int main(void) {
    uint32_t cases_in[]  = {0, 1, 2, 3, 4, 5, 8, 16, 31, 32, 1024, 1025};
    uint32_t cases_exp[] = {0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0};
    int n = sizeof(cases_in) / sizeof(cases_in[0]);

    int pass_count = 0;
    printf("Baseline Version Test\n");

    for (int i = 0; i < n; i++) {
        uint32_t x = cases_in[i];
        int got = isPowerOfTwo_baseline(x);
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
