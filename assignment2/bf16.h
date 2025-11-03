#ifndef BF16_H
#define BF16_H

#include <stdbool.h>
#include <stdint.h>

typedef struct {
    uint16_t bits;
} bf16_t;

#define BF16_EXP_BIAS 127
#define BF16_SIGN_MASK 0x8000U
#define BF16_EXP_MASK 0x7F80U
#define BF16_MANT_MASK 0x007FU

#define BF16_NAN() ((bf16_t) {.bits = 0x7FC0})
#define BF16_ZERO() ((bf16_t) {.bits = 0x0000})

bool bf16_isnan(bf16_t a);
bool bf16_isinf(bf16_t a);
bool bf16_iszero(bf16_t a);
bf16_t bf16_add(bf16_t a, bf16_t b);
bf16_t bf16_sub(bf16_t a, bf16_t b);
bf16_t bf16_mul(bf16_t a, bf16_t b);
bf16_t bf16_div(bf16_t a, bf16_t b);

#endif /* BF16_H */
