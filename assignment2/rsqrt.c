#include <stdint.h>

extern uint32_t clz32(uint32_t value);

/* Reciprocal square root lookup table scaled by 2^16 */
const uint32_t rsqrt_table[32] = {
    65536, 46341, 32768, 23170, 16384,
    11585,  8192,  5793,  4096,  2896,
     2048,  1448,  1024,   724,   512,
      362,   256,   181,   128,    90,
       64,    45,    32,    23,    16,
       11,     8,     6,     4,     3,
        2,     1
};

/* Shift-add 32-bit multiplication that returns a 64-bit product */
uint64_t rsqrt_mul32(uint32_t a, uint32_t b)
{
    uint64_t result = 0;
    uint64_t multiplicand = a;

    while (b) {
        if (b & 1u)
            result += multiplicand;
        multiplicand <<= 1;
        b >>= 1;
    }
    return result;
}

/* Multiply a 32-bit value with a 64-bit value using shift-add steps */
uint64_t rsqrt_mul32_u64(uint32_t a, uint64_t b)
{
    uint32_t lo = (uint32_t) b;
    uint32_t hi = (uint32_t) (b >> 32);
    uint64_t result = rsqrt_mul32(a, lo);

    if (hi) {
        uint64_t hi_part = rsqrt_mul32(a, hi);
        result += hi_part << 32;
    }
    return result;
}

uint32_t fast_rsqrt(uint32_t x)
{
    if (x == 0)
        return 0;

    uint32_t exp = 31u - clz32(x);
    uint32_t base = 1u << exp;
    uint32_t y = rsqrt_table[exp];
    uint32_t y_next = (exp < 31u) ? rsqrt_table[exp + 1u] : 0u;
    uint32_t delta = y - y_next;

    uint64_t frac_num = ((uint64_t) (x - base) << 16);
    uint32_t frac = (uint32_t) (frac_num >> exp);
    uint32_t interp = (uint32_t) (rsqrt_mul32(delta, frac) >> 16);
    y -= interp;

    const uint64_t scale_sq = 3ull << 32;
    for (int i = 0; i < 2; ++i) {
        uint64_t y_sq = rsqrt_mul32(y, y);
        uint64_t prod = rsqrt_mul32_u64(x, y_sq);
        uint64_t term = (prod >= scale_sq) ? 0 : (scale_sq - prod);

        uint64_t num = rsqrt_mul32_u64(y, term);
        y = (uint32_t) (num >> 33);
        if (y == 0)
            y = 1;
    }

    return y;
}
