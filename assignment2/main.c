#include <stdbool.h>
#include <stdint.h>
#include <string.h>

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

/* ============= BFloat16 Implementation ============= */

typedef struct {
    uint16_t bits;
} bf16_t;

#define BF16_EXP_BIAS 127
#define BF16_SIGN_MASK 0x8000U
#define BF16_EXP_MASK 0x7F80U
#define BF16_MANT_MASK 0x007FU

#define BF16_NAN() ((bf16_t) {.bits = 0x7FC0})
#define BF16_ZERO() ((bf16_t) {.bits = 0x0000})

static const bf16_t bf16_one = {.bits = 0x3F80};
static const bf16_t bf16_two = {.bits = 0x4000};

static inline bool bf16_isnan(bf16_t a)
{
    return ((a.bits & BF16_EXP_MASK) == BF16_EXP_MASK) &&
           (a.bits & BF16_MANT_MASK);
}

static inline bool bf16_isinf(bf16_t a)
{
    return ((a.bits & BF16_EXP_MASK) == BF16_EXP_MASK) &&
           !(a.bits & BF16_MANT_MASK);
}

static inline bool bf16_iszero(bf16_t a)
{
    return !(a.bits & 0x7FFF);
}

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

static inline bf16_t bf16_add(bf16_t a, bf16_t b)
{
    uint16_t sign_a = a.bits >> 15 & 0x1, sign_b = b.bits >> 15 & 1;
    int16_t exp_a = a.bits >> 7 & 0xFF, exp_b = b.bits >> 7 & 0xFF;
    uint16_t mant_a = a.bits & 0x7F, mant_b = b.bits & 0x7F;

    /* Infinity and NaN */
    if (exp_a == 0xFF) {
        if (mant_a)
            return a;
        if (exp_b == 0xFF)
            return (mant_b || sign_a == sign_b) ? b : BF16_NAN();
        return a;
    }

    /* if a is normal/denormal, but b is infinity/NaN */
    if (exp_b == 0xFF)
        return b;

    /* if a == 0, b == 0 */
    if (!exp_a && !mant_a)
        return b;
    if (!exp_b && !mant_b)
        return a;

    /* if a, b is normal */
    if (exp_a)
        mant_a |= 0x80;
    if (exp_b)
        mant_b |= 0x80;

    int16_t exp_diff = exp_a - exp_b;
    uint16_t result_sign;
    int16_t result_exp;
    uint32_t result_mant;

    /* deal with result of exp */
    if (exp_diff > 0) {
        result_exp = exp_b;
        if (exp_diff > 8)
            return a;
        mant_a <<= exp_diff;
    } else if (exp_diff < 0) {
        result_exp = exp_a;
        if (exp_diff < -8)
            return b;
        mant_b <<= -exp_diff;
    } else
        result_exp = exp_a;

    if (sign_a == sign_b) {
        result_sign = sign_a;
        result_mant = (uint32_t) mant_a + mant_b;
        uint32_t lz = clz(result_mant);
        for (unsigned i = 0; i < 32 - lz - 8; i++) {
            result_mant >>= 1;
            if (++result_exp >= 255)
                return BF16_NAN();
        }
    } else {
        if (mant_a >= mant_b) {
            result_sign = sign_a;
            result_mant = mant_a - mant_b;
        } else {
            result_sign = sign_b;
            result_mant = mant_b - mant_a;
        }
        if (!result_mant)
            return BF16_ZERO();
        if (result_mant < 0x80) {
            while (!(result_mant & 0x80)) {
                result_mant <<= 1;
                if (--result_exp <= 0)
                    return BF16_ZERO();
            }
        } else {
            uint32_t lz = clz(result_mant);
            for (unsigned i = 0; i < 32 - lz - 8; i++) {
                result_mant >>= 1;
                if (++result_exp >= 255)
                    return BF16_NAN();
            }
        }
    }
    return (bf16_t) {
        .bits =
            result_sign << 15 | (result_exp & 0xFF) << 7 | result_mant & 0x7F,
    };
}

static inline bf16_t bf16_sub(bf16_t a, bf16_t b)
{
    b.bits ^= 0x8000U;
    return bf16_add(a, b);
}

static inline bf16_t bf16_mul(bf16_t a, bf16_t b)
{
    uint16_t sign_a = (a.bits >> 15) & 1;
    uint16_t sign_b = (b.bits >> 15) & 1;
    int16_t exp_a = ((a.bits >> 7) & 0xFF);
    int16_t exp_b = ((b.bits >> 7) & 0xFF);
    uint16_t mant_a = a.bits & 0x7F;
    uint16_t mant_b = b.bits & 0x7F;

    uint16_t result_sign = sign_a ^ sign_b;

    if (exp_a == 0xFF) {
        if (mant_a)
            return a;
        if (!exp_b && !mant_b)
            return BF16_NAN();
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    }
    if (exp_b == 0xFF) {
        if (mant_b)
            return b;
        if (!exp_a && !mant_a)
            return BF16_NAN();
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    }
    if ((!exp_a && !mant_a) || (!exp_b && !mant_b))
        return (bf16_t) {.bits = result_sign << 15};

    int16_t exp_adjust = 0;
    if (!exp_a) {
        while (!(mant_a & 0x80)) {
            mant_a <<= 1;
            exp_adjust--;
        }
        exp_a = 1;
    } else
        mant_a |= 0x80;
    if (!exp_b) {
        while (!(mant_b & 0x80)) {
            mant_b <<= 1;
            exp_adjust--;
        }
        exp_b = 1;
    } else
        mant_b |= 0x80;

    uint32_t result_mant = (uint32_t) mant_a * mant_b;
    int32_t result_exp = (int32_t) exp_a + exp_b - BF16_EXP_BIAS + exp_adjust;

    if (result_mant & 0x8000) {
        result_mant = (result_mant >> 8) & 0x7F;
        result_exp++;
    } else
        result_mant = (result_mant >> 7) & 0x7F;

    if (result_exp >= 0xFF)
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    if (result_exp <= 0) {
        if (result_exp < -6)
            return (bf16_t) {.bits = result_sign << 15};
        result_mant >>= (1 - result_exp);
        result_exp = 0;
    }

    return (bf16_t) {.bits = (result_sign << 15) | ((result_exp & 0xFF) << 7) |
                             (result_mant & 0x7F)};
}

static inline bf16_t bf16_div(bf16_t a, bf16_t b)
{
    uint16_t sign_a = (a.bits >> 15) & 1;
    uint16_t sign_b = (b.bits >> 15) & 1;
    int16_t exp_a = ((a.bits >> 7) & 0xFF);
    int16_t exp_b = ((b.bits >> 7) & 0xFF);
    uint16_t mant_a = a.bits & 0x7F;
    uint16_t mant_b = b.bits & 0x7F;

    uint16_t result_sign = sign_a ^ sign_b;

    if (exp_b == 0xFF) {
        if (mant_b)
            return b;
        /* Inf/Inf = NaN */
        if (exp_a == 0xFF && !mant_a)
            return BF16_NAN();
        return (bf16_t) {.bits = result_sign << 15};
    }
    if (!exp_b && !mant_b) {
        if (!exp_a && !mant_a)
            return BF16_NAN();
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    }
    if (exp_a == 0xFF) {
        if (mant_a)
            return a;
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    }
    if (!exp_a && !mant_a)
        return (bf16_t) {.bits = result_sign << 15};

    if (exp_a)
        mant_a |= 0x80;
    if (exp_b)
        mant_b |= 0x80;

    uint32_t dividend = (uint32_t) mant_a << 15;
    uint32_t divisor = mant_b;
    uint32_t quotient = 0;

    for (int i = 0; i < 16; i++) {
        quotient <<= 1;
        if (dividend >= (divisor << (15 - i))) {
            dividend -= (divisor << (15 - i));
            quotient |= 1;
        }
    }

    int32_t result_exp = (int32_t) exp_a - exp_b + BF16_EXP_BIAS;

    if (!exp_a)
        result_exp--;
    if (!exp_b)
        result_exp++;

    if (quotient & 0x8000)
        quotient >>= 8;
    else {
        while (!(quotient & 0x8000) && result_exp > 1) {
            quotient <<= 1;
            result_exp--;
        }
        quotient >>= 8;
    }
    quotient &= 0x7F;

    if (result_exp >= 0xFF)
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    if (result_exp <= 0)
        return (bf16_t) {.bits = result_sign << 15};
    return (bf16_t) {.bits = (result_sign << 15) | ((result_exp & 0xFF) << 7) |
                             (quotient & 0x7F)};
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

int main(void)
{
    uint64_t cycles_elapsed, instret_elapsed;

    /* ChaCha20 section removed */

    TEST_LOGGER("\n=== BFloat16 Tests ===\n\n");

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

    TEST_LOGGER("\n=== UF8 Tests ===\n\n");

    /* Test 6: decode */
    TEST_LOGGER("Test 6: uf8_decode\n");
    test_uf8_decode(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 7: encode */
    TEST_LOGGER("Test 7: uf8_encode\n");
    test_uf8_encode(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);
    TEST_LOGGER("\n");

    /* Test 8: clz32 */
    TEST_LOGGER("Test 8: uf8_clz32\n");
    test_uf8_clz32(&cycles_elapsed, &instret_elapsed);

    TEST_LOGGER("  Cycles: ");
    print_dec((unsigned long) cycles_elapsed);
    TEST_LOGGER("  Instructions: ");
    print_dec((unsigned long) instret_elapsed);

    TEST_LOGGER("\n=== All Tests Completed ===\n");

    return 0;
}
