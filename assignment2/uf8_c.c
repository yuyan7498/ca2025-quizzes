#include <stdint.h>

static inline unsigned uf8c_clz(uint32_t x)
{
    int n = 32;
    int c = 16;
    do {
        uint32_t y = x >> c;
        if (y) {
            n -= c;
            x = y;
        }
        c >>= 1;
    } while (c);
    return (unsigned) (n - x);
}

uint32_t uf8_decode_c(uint32_t uf8)
{
    uint32_t mantissa = uf8 & 0x0f;
    uint32_t exponent = uf8 >> 4;
    uint32_t offset = (0x7FFFu >> (15 - exponent)) << 4;
    return (mantissa << exponent) + offset;
}

uint32_t uf8_encode_c(uint32_t value)
{
    if (value < 16)
        return value & 0xffu;

    int lz = uf8c_clz(value);
    int msb = 31 - lz;

    uint32_t exponent = 0;
    uint32_t overflow = 0;

    if (msb >= 5) {
        exponent = (uint32_t) (msb - 4);
        if (exponent > 15)
            exponent = 15;

        for (uint32_t e = 0; e < exponent; e++)
            overflow = (overflow << 1) + 16;

        while (exponent > 0 && value < overflow) {
            overflow = (overflow - 16) >> 1;
            exponent--;
        }
    }

    while (exponent < 15) {
        uint32_t next_overflow = (overflow << 1) + 16;
        if (value < next_overflow)
            break;
        overflow = next_overflow;
        exponent++;
    }

    uint32_t mantissa = (value - overflow) >> exponent;
    return ((exponent & 0x0fu) << 4) | (mantissa & 0x0fu);
}

uint32_t uf8_clz32_c(uint32_t value)
{
    return uf8c_clz(value);
}
