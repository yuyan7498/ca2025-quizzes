#include <stdbool.h>
#include <stdint.h>
#include <limits.h>
#include <string.h>

#include "bf16.h"

#define printstr(ptr, length)                   \
    do {                                        \
        asm volatile(                           \
            "add a7, x0, 0x40;"                 \
            "add a0, x0, 0x1;" /* stdout */     \
            "add a1, x0, %0;"                   \
            "mv a2, %1;" /* length character */ \
            "ecall;"                            \
            :                                   \
            : "r"(ptr), "r"(length)             \
            : "a0", "a1", "a2", "a7");          \
    } while (0)

#define TEST_OUTPUT(msg, length) printstr(msg, length)

#define TEST_LOGGER(msg)                     \
    {                                        \
        char _msg[] = msg;                   \
        TEST_OUTPUT(_msg, sizeof(_msg) - 1); \
    }

extern uint64_t get_cycles(void);
extern uint64_t get_instret(void);
extern uint32_t decode(uint32_t uf8);
extern uint32_t encode(uint32_t value);
extern uint32_t clz32(uint32_t value);
extern uint32_t uf8_decode_c(uint32_t uf8);
extern uint32_t uf8_encode_c(uint32_t value);
extern uint32_t uf8_clz32_c(uint32_t value);
extern uint32_t fast_rsqrt(uint32_t x);
extern uint32_t fast_rsqrt_asm(uint32_t x);
extern uint32_t bf16_isnan_asm(uint32_t bits);
extern uint32_t bf16_isinf_asm(uint32_t bits);
extern uint32_t bf16_iszero_asm(uint32_t bits);
extern uint32_t f32_to_bf16_asm(uint32_t value);
extern uint32_t bf16_to_f32_asm(uint32_t value);
extern uint32_t bf16_add_asm(uint32_t a_bits, uint32_t b_bits);
extern uint32_t bf16_sub_asm(uint32_t a_bits, uint32_t b_bits);
extern uint32_t bf16_mul_asm(uint32_t a_bits, uint32_t b_bits);
extern uint32_t bf16_div_asm(uint32_t a_bits, uint32_t b_bits);
extern void hanoi_run(void);

/* Bare metal memcpy implementation */
void *memcpy(void *dest, const void *src, size_t n)
{
    uint8_t *d = (uint8_t *) dest;
    const uint8_t *s = (const uint8_t *) src;
    while (n--)
        *d++ = *s++;
    return dest;
}

/* Software division for RV32I (no M extension) */
static unsigned long udiv(unsigned long dividend, unsigned long divisor)
{
    if (divisor == 0)
        return 0;

    unsigned long quotient = 0;
    unsigned long remainder = 0;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= (1UL << i);
        }
    }

    return quotient;
}

static unsigned long umod(unsigned long dividend, unsigned long divisor)
{
    if (divisor == 0)
        return 0;

    unsigned long remainder = 0;

    for (int i = 31; i >= 0; i--) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1;

        if (remainder >= divisor) {
            remainder -= divisor;
        }
    }

    return remainder;
}

static uint64_t udiv64(uint64_t dividend, uint64_t divisor)
{
    if (divisor == 0)
        return 0;

    uint64_t quotient = 0;
    uint64_t remainder = 0;

    for (int i = 63; i >= 0; --i) {
        remainder <<= 1;
        remainder |= (dividend >> i) & 1ull;

        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= (1ull << i);
        }
    }

    return quotient;
}

/* Software multiplication for RV32I (no M extension) */
static uint32_t umul(uint32_t a, uint32_t b)
{
    uint32_t result = 0;
    while (b) {
        if (b & 1)
            result += a;
        a <<= 1;
        b >>= 1;
    }
    return result;
}

/* Provide __mulsi3 for GCC */
uint32_t __mulsi3(uint32_t a, uint32_t b)
{
    return umul(a, b);
}

typedef uint32_t (*fast_rsqrt_fn_t)(uint32_t);

static uint64_t isqrt_u64(uint64_t value)
{
    uint64_t result = 0;
    uint64_t bit = 1ull << 62;

    while (bit > value)
        bit >>= 2;

    while (bit != 0) {
        if (value >= result + bit) {
            value -= result + bit;
            result = (result >> 1) + bit;
        } else {
            result >>= 1;
        }
        bit >>= 2;
    }

    return result;
}

/* Simple integer to hex string conversion */
static void print_hex(unsigned long val)
{
    char buf[20];
    char *p = buf + sizeof(buf) - 1;
    *p = '\n';
    p--;

    if (val == 0) {
        *p = '0';
        p--;
    } else {
        while (val > 0) {
            int digit = val & 0xf;
            *p = (digit < 10) ? ('0' + digit) : ('a' + digit - 10);
            p--;
            val >>= 4;
        }
    }

    p++;
    printstr(p, (buf + sizeof(buf) - p));
}

/* Simple integer to decimal string conversion */
static void print_dec(unsigned long val)
{
    char buf[20];
    char *p = buf + sizeof(buf) - 1;
    *p = '\n';
    p--;

    if (val == 0) {
        *p = '0';
        p--;
    } else {
        while (val > 0) {
            *p = '0' + umod(val, 10);
            p--;
            val = udiv(val, 10);
        }
    }

    p++;
    printstr(p, (buf + sizeof(buf) - p));
}
/* ============= Test Suite ============= */

static void test_bf16_add(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_add\n");

    /* 1.0 + 1.0 = 2.0 */
    bf16_t a = {.bits = 0x3F80}; /* 1.0 */
    bf16_t b = {.bits = 0x3F80}; /* 1.0 */
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    bf16_t result = bf16_add(a, b);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("  1.0 + 1.0 = ");
    print_hex(result.bits);

    /* Expected: 0x4000 (2.0) */
    if (result.bits == 0x4000) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED (expected 0x4000)\n");
    }
}

static void test_bf16_sub(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_sub\n");

    /* 3.0 - 2.0 = 1.0 */
    bf16_t a = {.bits = 0x4040}; /* 3.0 */
    bf16_t b = {.bits = 0x4000}; /* 2.0 */
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    bf16_t result = bf16_sub(a, b);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("  3.0 - 2.0 = ");
    print_hex(result.bits);

    /* Expected: 0x3F80 (1.0) */
    if (result.bits == 0x3F80) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED (expected 0x3F80)\n");
    }
}

static void test_bf16_mul(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_mul\n");

    /* 2.0 * 3.0 = 6.0 */
    bf16_t a = {.bits = 0x4000}; /* 2.0 */
    bf16_t b = {.bits = 0x4040}; /* 3.0 */
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    bf16_t result = bf16_mul(a, b);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("  2.0 * 3.0 = ");
    print_hex(result.bits);

    /* Expected: 0x40C0 (6.0) */
    if (result.bits == 0x40C0) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED (expected 0x40C0)\n");
    }
}

static void test_bf16_div(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_div\n");

    /* 6.0 / 2.0 = 3.0 */
    bf16_t a = {.bits = 0x40C0}; /* 6.0 */
    bf16_t b = {.bits = 0x4000}; /* 2.0 */
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    bf16_t result = bf16_div(a, b);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("  6.0 / 2.0 = ");
    print_hex(result.bits);

    /* Expected: 0x4040 (3.0) */
    if (result.bits == 0x4040) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED (expected 0x4040)\n");
    }
}

static void test_bf16_special_cases(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_special_cases\n");

    /* Test zero */
    bf16_t zero = BF16_ZERO();
    bf16_t nan = BF16_NAN();
    bf16_t inf = {.bits = 0x7F80};

    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();

    bool zero_ok = bf16_iszero(zero);
    bool nan_ok = bf16_isnan(nan);
    bool inf_ok = bf16_isinf(inf);

    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("  bf16_iszero(0): ");
    if (zero_ok) {
        TEST_LOGGER("PASSED\n");
    } else {
        TEST_LOGGER("FAILED\n");
    }

    TEST_LOGGER("  bf16_isnan(NaN): ");
    if (nan_ok) {
        TEST_LOGGER("PASSED\n");
    } else {
        TEST_LOGGER("FAILED\n");
    }

    TEST_LOGGER("  bf16_isinf(Inf): ");
    if (inf_ok) {
        TEST_LOGGER("PASSED\n");
    } else {
        TEST_LOGGER("FAILED\n");
    }
}

static void test_bf16_add_asm(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_add_asm\n");

    bf16_t a = {.bits = 0x3F80};
    bf16_t b = {.bits = 0x3F80};
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t result_bits = bf16_add_asm(a.bits, b.bits);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    bf16_t result = {.bits = (uint16_t) result_bits};
    TEST_LOGGER("  1.0 + 1.0 = ");
    print_hex(result.bits);

    if (result.bits == 0x4000) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED (expected 0x4000)\n");
    }
}

static void test_bf16_sub_asm(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_sub_asm\n");

    bf16_t a = {.bits = 0x4040};
    bf16_t b = {.bits = 0x4000};
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t result_bits = bf16_sub_asm(a.bits, b.bits);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    bf16_t result = {.bits = (uint16_t) result_bits};
    TEST_LOGGER("  3.0 - 2.0 = ");
    print_hex(result.bits);

    if (result.bits == 0x3F80) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED (expected 0x3F80)\n");
    }
}

static void test_bf16_mul_asm(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_mul_asm\n");

    bf16_t a = {.bits = 0x4000};
    bf16_t b = {.bits = 0x4040};
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t result_bits = bf16_mul_asm(a.bits, b.bits);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    bf16_t result = {.bits = (uint16_t) result_bits};
    TEST_LOGGER("  2.0 * 3.0 = ");
    print_hex(result.bits);

    if (result.bits == 0x40C0) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED (expected 0x40C0)\n");
    }
}

static void test_bf16_div_asm(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_div_asm\n");

    bf16_t a = {.bits = 0x40C0};
    bf16_t b = {.bits = 0x4000};
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t result_bits = bf16_div_asm(a.bits, b.bits);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    bf16_t result = {.bits = (uint16_t) result_bits};
    TEST_LOGGER("  6.0 / 2.0 = ");
    print_hex(result.bits);

    if (result.bits == 0x4040) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED (expected 0x4040)\n");
    }
}

static void test_bf16_special_cases_asm(uint64_t *cycles, uint64_t *instret)
{
    TEST_LOGGER("Test: bf16_special_cases_asm\n");

    const uint32_t zero = 0x0000;
    const uint32_t nan = 0x7FC0;
    const uint32_t inf = 0x7F80;

    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();

    bool zero_ok = bf16_iszero_asm(zero);
    bool nan_ok = bf16_isnan_asm(nan);
    bool inf_ok = bf16_isinf_asm(inf);

    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("  bf16_iszero_asm(0): ");
    if (zero_ok) {
        TEST_LOGGER("PASSED\n");
    } else {
        TEST_LOGGER("FAILED\n");
    }

    TEST_LOGGER("  bf16_isnan_asm(NaN): ");
    if (nan_ok) {
        TEST_LOGGER("PASSED\n");
    } else {
        TEST_LOGGER("FAILED\n");
    }

    TEST_LOGGER("  bf16_isinf_asm(Inf): ");
    if (inf_ok) {
        TEST_LOGGER("PASSED\n");
    } else {
        TEST_LOGGER("FAILED\n");
    }
}

static void test_uf8_decode(uint64_t *cycles, uint64_t *instret)
{
    const uint32_t input = 31;
    const uint32_t expected = 46;
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t got = decode(input);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("Test: uf8_decode\n");
    TEST_LOGGER("  input: ");
    print_dec((unsigned long) input);
    TEST_LOGGER("  expected: ");
    print_dec((unsigned long) expected);
    TEST_LOGGER("  got: ");
    print_dec((unsigned long) got);

    if (got == expected) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED\n");
    }
}

static void test_uf8_encode(uint64_t *cycles, uint64_t *instret)
{
    const uint32_t input = 480;
    const uint32_t expected = 79;
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t got = encode(input);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("Test: uf8_encode\n");
    TEST_LOGGER("  input: ");
    print_dec((unsigned long) input);
    TEST_LOGGER("  expected: ");
    print_dec((unsigned long) expected);
    TEST_LOGGER("  got: ");
    print_dec((unsigned long) got);

    if (got == expected) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED\n");
    }
}

static void test_uf8_clz32(uint64_t *cycles, uint64_t *instret)
{
    const uint32_t input = 0x00F00000;
    const uint32_t expected = 8;
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t got = clz32(input);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("Test: uf8_clz32\n");
    TEST_LOGGER("  input: 0x");
    print_hex(input);
    TEST_LOGGER("  expected: ");
    print_dec((unsigned long) expected);
    TEST_LOGGER("  got: ");
    print_dec((unsigned long) got);

    if (got == expected) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED\n");
    }
}

static void test_uf8_decode_c(uint64_t *cycles, uint64_t *instret)
{
    const uint32_t input = 31;
    const uint32_t expected = 46;
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t got = uf8_decode_c(input);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("Test: uf8_decode_c\n");
    TEST_LOGGER("  input: ");
    print_dec((unsigned long) input);
    TEST_LOGGER("  expected: ");
    print_dec((unsigned long) expected);
    TEST_LOGGER("  got: ");
    print_dec((unsigned long) got);

    if (got == expected) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED\n");
    }
}

static void test_uf8_encode_c(uint64_t *cycles, uint64_t *instret)
{
    const uint32_t input = 480;
    const uint32_t expected = 79;
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t got = uf8_encode_c(input);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("Test: uf8_encode_c\n");
    TEST_LOGGER("  input: ");
    print_dec((unsigned long) input);
    TEST_LOGGER("  expected: ");
    print_dec((unsigned long) expected);
    TEST_LOGGER("  got: ");
    print_dec((unsigned long) got);

    if (got == expected) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED\n");
    }
}

static void test_uf8_clz32_c(uint64_t *cycles, uint64_t *instret)
{
    const uint32_t input = 0x00F00000;
    const uint32_t expected = 8;
    uint64_t start_cycles = get_cycles();
    uint64_t start_instret = get_instret();
    uint32_t got = uf8_clz32_c(input);
    uint64_t end_cycles = get_cycles();
    uint64_t end_instret = get_instret();

    if (cycles)
        *cycles = end_cycles - start_cycles;
    if (instret)
        *instret = end_instret - start_instret;

    TEST_LOGGER("Test: uf8_clz32_c\n");
    TEST_LOGGER("  input: 0x");
    print_hex(input);
    TEST_LOGGER("  expected: ");
    print_dec((unsigned long) expected);
    TEST_LOGGER("  got: ");
    print_dec((unsigned long) got);

    if (got == expected) {
        TEST_LOGGER("  PASSED\n");
    } else {
        TEST_LOGGER("  FAILED\n");
    }
}

static void run_fast_rsqrt_exact(fast_rsqrt_fn_t fn)
{
    static const struct {
        uint32_t x;
        uint32_t expected;
    } cases[] = {
        {1u, 65536u},
        {4u, 32768u},
        {16u, 16384u},
        {256u, 4096u},
        {65536u, 256u},
        {UINT32_MAX, 1u},
    };

    bool first_fail = true;
    uint32_t fail_x = 0, fail_expected = 0, fail_got = 0;

    for (unsigned i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
        uint32_t got = fn(cases[i].x);

        TEST_LOGGER("  input: ");
        print_dec((unsigned long) cases[i].x);
        TEST_LOGGER("  expected: ");
        print_dec((unsigned long) cases[i].expected);
        TEST_LOGGER("  got: ");
        print_dec((unsigned long) got);

        if (got == cases[i].expected) {
            TEST_LOGGER("  Pass\n");
        } else {
            if (first_fail) {
                fail_x = cases[i].x;
                fail_expected = cases[i].expected;
                fail_got = got;
                first_fail = false;
            }
            TEST_LOGGER("  FAIL\n");
        }
        TEST_LOGGER("\n");
    }

    if (!first_fail) {
        TEST_LOGGER("  First failure summary -> input: ");
        print_dec((unsigned long) fail_x);
        TEST_LOGGER("  expected: ");
        print_dec((unsigned long) fail_expected);
        TEST_LOGGER("  got: ");
        print_dec((unsigned long) fail_got);
        TEST_LOGGER("\n");
    }
}

static void run_fast_rsqrt_accuracy(fast_rsqrt_fn_t fn)
{
    static const uint32_t samples[] = {
        2u, 3u, 5u, 10u, 20u, 50u, 12345u, 100000u, 1000000u, 3000000000u
    };

    for (unsigned i = 0; i < sizeof(samples) / sizeof(samples[0]); ++i) {
        uint32_t x = samples[i];
        uint32_t y = fn(x);

        uint64_t norm = (uint64_t) x << 32;
        uint64_t root = isqrt_u64(norm);
        if (root == 0)
            root = 1;

        uint32_t expected = (uint32_t) udiv64((uint64_t)1 << 32, root);
        uint32_t tolerance = expected / 8u;
        if (tolerance < 2u)
            tolerance = 2u;

        uint32_t delta = (y > expected) ? (y - expected) : (expected - y);

        TEST_LOGGER("  input: ");
        print_dec((unsigned long) x);
        TEST_LOGGER("  expected: ");
        print_dec((unsigned long) expected);
        TEST_LOGGER("  got: ");
        print_dec((unsigned long) y);
        TEST_LOGGER("  tolerance: ");
        print_dec((unsigned long) tolerance);
        TEST_LOGGER("  delta: ");
        print_dec((unsigned long) delta);

        if (delta <= tolerance) {
            TEST_LOGGER("  Pass\n");
        } else {
            TEST_LOGGER("  FAIL\n");
        }
        TEST_LOGGER("\n");
    }
}

int main(void)
{
    uint64_t start_cycles, end_cycles, cycles_elapsed;
    uint64_t start_instret, end_instret, instret_elapsed;

    
    TEST_LOGGER("\n=== BFloat16 ASM Tests ===\n\n");

    /* Test 6: Addition (ASM) */
    TEST_LOGGER("Test 6: bf16_add_asm\n");
    test_bf16_add_asm(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 7: Subtraction (ASM) */
    TEST_LOGGER("Test 7: bf16_sub_asm\n");
    test_bf16_sub_asm(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 8: Multiplication (ASM) */
    TEST_LOGGER("Test 8: bf16_mul_asm\n");
    test_bf16_mul_asm(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 9: Division (ASM) */
    TEST_LOGGER("Test 9: bf16_div_asm\n");
    test_bf16_div_asm(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 10: Special cases (ASM) */
    TEST_LOGGER("Test 10: bf16_special_cases_asm\n");
    test_bf16_special_cases_asm(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);

    TEST_LOGGER("\n=== BFloat16 C Tests ===\n\n");

    /* Test 1: Addition */
    TEST_LOGGER("Test 1: bf16_add\n");
    test_bf16_add(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 2: Subtraction */
    TEST_LOGGER("Test 2: bf16_sub\n");
    test_bf16_sub(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 3: Multiplication */
    TEST_LOGGER("Test 3: bf16_mul\n");
    test_bf16_mul(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 4: Division */
    TEST_LOGGER("Test 4: bf16_div\n");
    test_bf16_div(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 5: Special cases */
    TEST_LOGGER("Test 5: bf16_special_cases\n");
    test_bf16_special_cases(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);

    TEST_LOGGER("\n=== UF8 ASM Tests ===\n\n");

    /* Test 11: decode */
    TEST_LOGGER("Test 11: uf8_decode\n");
    test_uf8_decode(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 12: encode */
    TEST_LOGGER("Test 12: uf8_encode\n");
    test_uf8_encode(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 13: clz32 */
    TEST_LOGGER("Test 13: uf8_clz32\n");
    test_uf8_clz32(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    TEST_LOGGER("\n=== UF8 C Tests ===\n\n");

    /* Test 14: decode (C) */
    TEST_LOGGER("Test 14: uf8_decode_c\n");
    test_uf8_decode_c(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 15: encode (C) */
    TEST_LOGGER("Test 15: uf8_encode_c\n");
    test_uf8_encode_c(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 16: clz32 (C) */
    TEST_LOGGER("Test 16: uf8_clz32_c\n");
    test_uf8_clz32_c(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);

    TEST_LOGGER("\n=== fast_rsqrt Tests ===\n\n");

    TEST_LOGGER("Test 17: fast_rsqrt_exact (ASM)\n");
    start_cycles = get_cycles();
    start_instret = get_instret();

    run_fast_rsqrt_exact(fast_rsqrt_asm);

    end_cycles = get_cycles();
    end_instret = get_instret();
    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    TEST_LOGGER("Test 18: fast_rsqrt_accuracy (ASM)\n");
    start_cycles = get_cycles();
    start_instret = get_instret();

    run_fast_rsqrt_accuracy(fast_rsqrt_asm);

    end_cycles = get_cycles();
    end_instret = get_instret();
    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    TEST_LOGGER("Test 19: fast_rsqrt_exact (C)\n");
    start_cycles = get_cycles();
    start_instret = get_instret();

    run_fast_rsqrt_exact(fast_rsqrt);

    end_cycles = get_cycles();
    end_instret = get_instret();
    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    TEST_LOGGER("Test 20: fast_rsqrt_accuracy (C)\n");
    start_cycles = get_cycles();
    start_instret = get_instret();

    run_fast_rsqrt_accuracy(fast_rsqrt);

    end_cycles = get_cycles();
    end_instret = get_instret();
    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);

    TEST_LOGGER("\n=== Hanoi ASM ===\n\n");
    start_cycles = get_cycles();
    start_instret = get_instret();

    hanoi_run();

    end_cycles = get_cycles();
    end_instret = get_instret();
    cycles_elapsed = end_cycles - start_cycles;
    instret_elapsed = end_instret - start_instret;

    TEST_LOGGER("Total Hanoi Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("Total Hanoi Instructions: ");
    print_dec((unsigned long) instret_elapsed);

    TEST_LOGGER("\n=== All Tests Completed ===\n");

    return 0;
}
