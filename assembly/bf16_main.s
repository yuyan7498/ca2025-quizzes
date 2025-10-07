    .text
    .globl main
    .globl bf16_isnan
    .globl bf16_isinf
    .globl bf16_iszero
    .globl f32_to_bf16
    .globl bf16_to_f32
    .globl bf16_add
    .globl bf16_sub
    .globl bf16_mul
    .globl bf16_div
    .globl bf16_sqrt

# =========================================
# 共用常數（bf16）
# =========================================
    .equ BF16_SIGN_MASK, 0x8000
    .equ BF16_EXP_MASK,  0x7F80
    .equ BF16_MANT_MASK, 0x007F
    .equ BF16_EXP_BIAS,  127

    .equ BF16_POS_INF,   0x7F80
    .equ BF16_NEG_INF,   0xFF80
    .equ BF16_NAN,       0x7FC0
    .equ BF16_ZERO,      0x0000
    .equ BF16_NEG_ZERO,  0x8000

# =========================================
# main: 測資整合（A~G）
# =========================================
main:
    # ----------------------------
    # Section A: isnan / isinf / iszero
    # ----------------------------
    # A1
    li      a0, 0x7FC1
    jal     ra, bf16_isnan
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # A2
    li      a0, 0x7F80
    jal     ra, bf16_isnan
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # A3
    li      a0, 0x7F80
    jal     ra, bf16_isinf
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # A4
    li      a0, 0x0000
    jal     ra, bf16_iszero
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # A5
    li      a0, 0x3F80
    jal     ra, bf16_iszero
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # ----------------------------
    # Section B: f32_to_bf16
    # ----------------------------
    # B1
    li      a0, 0x7FC00000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # B2
    li      a0, 0x7F800000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # B3
    li      a0, 0x3F800000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # B4
    li      a0, 0x3F000000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # B5 tie-even (even)
    li      a0, 0x3F808000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # B6 tie-even (odd)
    li      a0, 0x3F818000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # ----------------------------
    # Section C: bf16_to_f32
    # ----------------------------
    # C1
    li      a0, 0x7FC0
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # C2
    li      a0, 0x7F80
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # C3
    li      a0, 0x3F80
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # C4
    li      a0, 0x3F00
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # C5
    li      a0, 0x0000
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # ----------------------------
    # Section D: add / sub
    # ----------------------------
    # D1
    li      a0, 0x3F80
    li      a1, 0x3F00
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # D2
    li      a0, 0x3F80
    li      a1, 0xBF80
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # D3
    li      a0, 0x3F80
    li      a1, 0x3B00
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # D4
    li      a0, 0x7F80
    li      a1, 0x3F80
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # D5
    li      a0, 0x7F80
    li      a1, 0xFF80
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # D6
    li      a0, 0x7FC1
    li      a1, 0x3F80
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # D7 (sub)
    li      a0, 0x3F80
    li      a1, 0x3F00
    jal     ra, bf16_sub
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # ----------------------------
    # Section E: mul
    # ----------------------------
    # E1
    li      a0, 0x3FC0
    li      a1, 0xBF00
    jal     ra, bf16_mul
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # ----------------------------
    # Section F: div
    # ----------------------------
    # F1
    li      a0, 0x3F80
    li      a1, 0x4000
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # F2
    li      a0, 0x3F80
    li      a1, 0x0000
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # F3
    li      a0, 0x0000
    li      a1, 0x4000
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # F4
    li      a0, 0x7F80
    li      a1, 0x4000
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # F5
    li      a0, 0x7FC0
    li      a1, 0x3F80
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # F6
    li      a0, 0x3F80
    li      a1, 0x7FC0
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # ----------------------------
    # Section G: sqrt
    # ----------------------------
    # G1: sqrt(1.0=0x3F80) -> 0x3F80
    li      a0, 0x3F80
    jal     ra, bf16_sqrt
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # G2: sqrt(0.25=0x3E80) -> 0x3F00 (0.5)
    li      a0, 0x3E80
    jal     ra, bf16_sqrt
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # G3: sqrt(+Inf) -> +Inf
    li      a0, BF16_POS_INF
    jal     ra, bf16_sqrt
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # G4: sqrt(NaN) -> NaN (回傳 a)
    li      a0, 0x7FC1
    jal     ra, bf16_sqrt
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # G5: sqrt(0) -> 0
    li      a0, 0x0000
    jal     ra, bf16_sqrt
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall
    # G6: sqrt(負數) -> NaN
    li      a0, 0xBF80           # -1.0
    jal     ra, bf16_sqrt
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # 結束
    li      a7, 10
    ecall

# ==================================================================================
# bool bf16_isnan(uint16_t bits)
# C: return ((bits & 0x7F80)==0x7F80) && (bits & 0x007F);
# 
#
#
#
#
#
#
# ==================================================================================
bf16_isnan:
    li      t2, 0x7F80
    and     t0, a0, t2
    bne     t0, t2, Lnan_false
    li      t3, 0x007F
    and     t1, a0, t3
    beq     t1, x0, Lnan_false
    li      a0, 1
    ret
Lnan_false:
    mv      a0, x0
    ret

# ==================================================================================
# bool bf16_isinf(uint16_t bits)
# C: return ((bits & 0x7F80)==0x7F80) && !(bits & 0x007F);
# 
#
#
#
#
#
#
# ==================================================================================
bf16_isinf:
    li      t2, 0x7F80
    and     t0, a0, t2
    bne     t0, t2, Linf_false
    li      t3, 0x007F
    and     t1, a0, t3
    bne     t1, x0, Linf_false
    li      a0, 1
    ret
Linf_false:
    mv      a0, x0
    ret

# ==================================================================================
# bool bf16_iszero(uint16_t bits)
# C: return !(bits & 0x7FFF);
# 
# 
#
#
#
#
#
# ==================================================================================
bf16_iszero:
    li      t0, 0x7FFF
    and     t0, a0, t0
    bne     t0, x0, Lzero_false
    li      a0, 1
    ret
Lzero_false:
    mv      a0, x0
    ret

# ==================================================================================
# bf16_t f32_to_bf16(uint32_t f32bits)
# C:
# If (exp==0xFF) return high16(f32bits);
# f32bits += ((high16&1) + 0x7FFF); return high16(f32bits);
#
#
#
#
#
# ==================================================================================
f32_to_bf16:
    # t0 = ((f32bits >> 23) & 0xFF)
    srli    t0, a0, 23
    andi    t0, t0, 0x0FF
    li      t1, 0x0FF
    beq     t0, t1, Lfte_special

    # RNE: f32bits += ((f32bits >> 16) & 1) + 0x7FFF
    srli    t2, a0, 16      # t2 = high16(f32bits)
    andi    t2, t2, 1       # t2 = (high16 & 1)
    li      t3, 0x7FFF
    add     t2, t2, t3
    add     a0, a0, t2

    # return high16(f32bits)
    srli    a0, a0, 16
    ret
Lfte_special:
    srli    a0, a0, 16
    li      t0, 0xFFFF
    and     a0, a0, t0
    ret

# ==================================================================================
# uint32_t bf16_to_f32(uint16_t bits)
# C: return ((uint32_t)bits)<<16;
# 
# 
#
#
#
#
#
# ==================================================================================
bf16_to_f32:
    li      t0, 0xFFFF
    and     a0, a0, t0      # 只取低 16 位
    slli    a0, a0, 16      # 左移 16 -> 放到 f32 高半部
    ret

# ==================================================================================
# bf16_add(a0=a.bits, a1=b.bits) -> a0
# 
# 
# 
#
#
#
#
#
# ==================================================================================
bf16_add:
    # ---- 取 sign / exp / mant ----
    srli    t0, a0, 15      # sign_a
    andi    t0, t0, 1
    srli    t1, a1, 15      # sign_b
    andi    t1, t1, 1

    srli    t2, a0, 7       # exp_a
    andi    t2, t2, 0xFF
    srli    t3, a1, 7       # exp_b
    andi    t3, t3, 0xFF
    andi    t4, a0, 0x7F    # mant_a
    andi    t5, a1, 0x7F    # mant_b

    # ---- 特例: a exponent == 0xFF ----
    li      t6, 0xFF
    bne     t2, t6, 1f      # if exp_a != 0xFF skip

    beq     t4, x0, La_is_inf       # mant_a==0 → a 是 Inf
    mv      a0, a0              # mant_a!=0 → a 是 NaN，回傳 a
    ret
La_is_inf:
    bne     t3, t6, Lret_a      # exp_b!=0xFF → 回傳 a
    beq     t5, x0, 0f          # mant_b==0 →  Inf
    mv      a0, a1              # mant_b!=0 → NaN，回傳 b
    ret
0:  # a=Inf, b=Inf
    bne     t0, t1, Lret_NaN    # sign_a!=sign_b → NaN
    mv      a0, a1              # sign_a==sign_b → 回傳 a
    ret
Lret_NaN:
    li      a0, 0x7FC0          # 回傳 NaN
    ret
Lret_a:
    mv      a0, a0
    ret
    # ---- 特例: b exponent == 0xFF ----
1:
    bne     t3, t6, 2f
    mv      a0, a1
    ret

    # ---- 特例: a == 0 → 回 b ----
2:
    beq     t2, x0, 3f
    j       4f
3:
    beq     t4, x0, Lret_b
    j       4f
Lret_b:
    mv      a0, a1
    ret

    # ---- 特例: b == 0 → 回 a ----
4:
    beq     t3, x0, 5f
    j       6f
5:
    beq     t5, x0, Lret_a2
    j       6f
Lret_a2:
    mv      a0, a0
    ret

    # ---- 規格化(補 hidden bit 1) ----
6:
    beq     t2, x0, 7f
    ori     t4, t4, 0x80    # mant_a |= 0x80
7:
    beq     t3, x0, 8f
    ori     t5, t5, 0x80    # mant_b |= 0x80
8:

    # ---- 指數對齊 ----
    sub     a2, t2, t3      # a2 = exp_a - exp_b
    beq     a2, x0, 9f      # if exp_a == exp_b skip
    blt     x0, a2, 10f     # if exp_a < exp_b

    neg     a3, a2
    li      t6, 8
    blt     t6, a3, Lret_b
    srl     t4, t4, a3
    mv      t6, t3
    j       11f
10:
    li      t6, 8
    blt     t6, a2, Lret_a2
    srl     t5, t5, a2
    mv      t6, t2
    j       11f
9:
    mv      t6, t2

11:
    bne     t0, t1, Ldiff_sign

    add     a4, t4, t5
    mv      a3, t0
    andi    a5, a4, 0x100
    beq     a5, x0, Lpack
    srli    a4, a4, 1
    addi    t6, t6, 1
    li      a5, 0xFF
    blt     t6, a5, Lpack
    slli    a3, a3, 15
    li      a5, 0x7F80
    or      a0, a3, a5
    ret

Ldiff_sign:
    bge     t4, t5, 12f
    sub     a4, t5, t4
    mv      a3, t1
    j       13f
12:
    sub     a4, t4, t5
    mv      a3, t0
13:
    beq     a4, x0, Lret_zero

14:
    andi    a5, a4, 0x80
    bne     a5, x0, Lpack
    slli    a4, a4, 1
    addi    t6, t6, -1
    blt     x0, t6, 14b
Lret_zero:
    mv      a0, x0
    ret

Lpack:
    slli    a3, a3, 15
    andi    a5, t6, 0xFF
    slli    a5, a5, 7
    andi    a4, a4, 0x7F
    or      a3, a3, a5
    or      a0, a3, a4
    ret

# ==================================================================================
# bf16_sub(a,b) = bf16_add(a, flip_sign(b))
# 
# 
# 
#
#
#
#
#
# ==================================================================================
bf16_sub:
    li      t0, 0x8000
    xor     a1, a1, t0
    j       bf16_add

# ==================================================================================
# bf16_mul(a0=a.bits, a1=b.bits) -> a0
# 
# 
# 
#
#
#
#
#
# ==================================================================================
bf16_mul:
    srli    t0, a0, 15
    andi    t0, t0, 1
    srli    t1, a1, 15
    andi    t1, t1, 1
    srli    t3, a0, 7
    andi    t3, t3, 0xFF
    srli    t4, a1, 7
    andi    t4, t4, 0xFF
    andi    t5, a0, 0x7F
    andi    t6, a1, 0x7F
    xor     t2, t0, t1

    li      a2, 0xFF
    bne     t3, a2, Lmul_chk_b
    bnez    t5, Lmul_ret_a
    beqz    t4, Lmul_inf_x_zero_chk
    j       Lmul_ret_sign_inf
Lmul_inf_x_zero_chk:
    beqz    t6, Lmul_ret_nan
    j       Lmul_ret_sign_inf

Lmul_chk_b:
    bne     t4, a2, Lmul_check_zero
    bnez    t6, Lmul_ret_b
    beqz    t3, Lmul_zero_inf_chk
    j       Lmul_ret_sign_inf
Lmul_zero_inf_chk:
    beqz    t5, Lmul_ret_nan
    j       Lmul_ret_sign_inf

Lmul_check_zero:
    beqz    t3, Lmul_a_mant0
    j       Lmul_b_zero
Lmul_a_mant0:
    beqz    t5, Lmul_ret_sign_zero
Lmul_b_zero:
    beqz    t4, Lmul_b_mant0
    j       Lmul_norm_in
Lmul_b_mant0:
    beqz    t6, Lmul_ret_sign_zero

Lmul_norm_in:
    li      a4, 0
    beqz    t3, Lmul_norm_a_sub
    ori     t5, t5, 0x80
    j       Lmul_norm_b_chk
Lmul_norm_a_sub:
Lmul_norm_a_loop:
    andi    a5, t5, 0x80
    bnez    a5, Lmul_norm_a_done
    slli    t5, t5, 1
    addi    a4, a4, -1
    j       Lmul_norm_a_loop
Lmul_norm_a_done:
    li      t3, 1

Lmul_norm_b_chk:
    beqz    t4, Lmul_norm_b_sub
    ori     t6, t6, 0x80
    j       Lmul_do
Lmul_norm_b_sub:
Lmul_norm_b_loop:
    andi    a5, t6, 0x80
    bnez    a5, Lmul_norm_b_done
    slli    t6, t6, 1
    addi    a4, a4, -1
    j       Lmul_norm_b_loop
Lmul_norm_b_done:
    li      t4, 1

Lmul_do:
    mv      a3, zero
    mv      a5, t6
    mv      a2, t5
    li      t0, 8
Lmul_loop:
    andi    t1, a5, 1
    beqz    t1, Lmul_skip_add
    add     a3, a3, a2
Lmul_skip_add:
    slli    a2, a2, 1
    srli    a5, a5, 1
    addi    t0, t0, -1
    bnez    t0, Lmul_loop

    add     a2, t3, t4
    add     a2, a2, a4
    addi    a2, a2, -127

    li      t0, 0x8000
    and     t1, a3, t0
    beqz    t1, Lmul_norm_else
    srli    a3, a3, 8
    andi    a3, a3, 0x7F
    addi    a2, a2, 1
    j       Lmul_after_norm
Lmul_norm_else:
    srli    a3, a3, 7
    andi    a3, a3, 0x7F
Lmul_after_norm:
    li      t0, 0xFF
    blt     a2, t0, Lmul_under
Lmul_ret_sign_inf:
    slli    a0, t2, 15
    li      t1, 0x7F80
    or      a0, a0, t1
    jr      ra

Lmul_under:
    blez    a2, Lmul_under_path
    j       Lmul_pack
Lmul_under_path:
    addi    t0, zero, -6
    blt     a2, t0, Lmul_ret_sign_zero
    li      t1, 1
    sub     t1, t1, a2
    beqz    t1, Lmul_under_done
Lmul_under_shift:
    srli    a3, a3, 1
    addi    t1, t1, -1
    bnez    t1, Lmul_under_shift
Lmul_under_done:
    mv      a2, zero

Lmul_pack:
    slli    a0, t2, 15
    andi    t0, a2, 0xFF
    slli    t0, t0, 7
    or      a0, a0, t0
    andi    t1, a3, 0x7F
    or      a0, a0, t1
    jr      ra

Lmul_ret_nan:
    li      a0, 0x7FC0
    jr      ra
Lmul_ret_a:
    mv      a0, a0
    jr      ra
Lmul_ret_b:
    mv      a0, a1
    jr      ra
Lmul_ret_sign_zero:
    slli    a0, t2, 15
    jr      ra

# ==================================================================================
# bf16_div:
# (a0=a.bits, a1=b.bits) -> a0
# 
# 
#
#
#
#
#
# ==================================================================================
bf16_div:
    addi    sp, sp, -16
    sw      ra, 12(sp)

    srli    t0, a0, 15
    andi    t0, t0, 1
    srli    t1, a1, 15
    andi    t1, t1, 1
    srli    t2, a0, 7
    andi    t2, t2, 0xFF
    srli    t3, a1, 7
    andi    t3, t3, 0xFF
    andi    t4, a0, 0x007F
    andi    t5, a1, 0x007F

    xor     t6, t0, t1
    slli    t6, t6, 15

    li      a4, 0xFF
    bne     t3, a4, Ldiv_not_b_inf
    bnez    t5, Ldiv_return_b
    li      a5, 0xFF
    bne     t2, a5, Ldiv_b_inf_zero
    bnez    t4, Ldiv_b_inf_zero
    li      a0, 0x7FC0
    j       Ldiv_ep
Ldiv_b_inf_zero:
    mv      a0, t6
    j       Ldiv_ep

Ldiv_not_b_inf:
    beqz    t3, Ldiv_chk_b_mant
    j       Ldiv_chk_a_inf
Ldiv_chk_b_mant:
    bnez    t5, Ldiv_chk_a_inf
    beqz    t2, Ldiv_both_zero
    j       Ldiv_by_zero_ret_inf
Ldiv_both_zero:
    beqz    t4, Ldiv_return_nan
Ldiv_by_zero_ret_inf:
    li      a0, 0x7F80
    or      a0, a0, t6
    j       Ldiv_ep

Ldiv_chk_a_inf:
    li      a4, 0xFF
    bne     t2, a4, Ldiv_a_not_inf
    bnez    t4, Ldiv_return_a
    li      a0, 0x7F80
    or      a0, a0, t6
    j       Ldiv_ep

Ldiv_a_not_inf:
    beqz    t2, Ldiv_a_zero_path
    j       Ldiv_normals
Ldiv_a_zero_path:
    bnez    t4, Ldiv_normals
    mv      a0, t6
    j       Ldiv_ep

Ldiv_return_a:
    mv      a0, a0
    j       Ldiv_ep
Ldiv_return_b:
    mv      a0, a1
    j       Ldiv_ep
Ldiv_return_nan:
    li      a0, 0x7FC0
    j       Ldiv_ep

Ldiv_normals:
    beqz    t2, Ldiv_no_imp_a
    ori     t4, t4, 0x80
Ldiv_no_imp_a:
    beqz    t3, Ldiv_no_imp_b
    ori     t5, t5, 0x80
Ldiv_no_imp_b:

    slli    a2, t4, 15
    mv      a3, t5
    li      a4, 0
    li      a5, 0
Ldiv_loop_cond:
    li      a7, 16
    bge     a5, a7, Ldiv_loop_end
    slli    a4, a4, 1
    li      a7, 15
    sub     a7, a7, a5
    sll     a7, a3, a7
    bltu    a2, a7, Ldiv_no_sub
    sub     a2, a2, a7
    ori     a4, a4, 1
Ldiv_no_sub:
    addi    a5, a5, 1
    j       Ldiv_loop_cond
Ldiv_loop_end:

    sub     a6, t2, t3
    li      a7, 127
    add     a6, a6, a7
    beqz    t2, Ldiv_adj_a_sub
    j       Ldiv_adj_b_add
Ldiv_adj_a_sub:
    addi    a6, a6, -1
Ldiv_adj_b_add:
    beqz    t3, Ldiv_adj_b_do
    j       Ldiv_norm_start
Ldiv_adj_b_do:
    addi    a6, a6, 1

Ldiv_norm_start:
    li      a7, 0x8000
    and     a7, a4, a7
    beqz    a7, Ldiv_shift_up
    srli    a4, a4, 8
    j       Ldiv_pack

Ldiv_shift_up:
Ldiv_norm_while:
    li      a7, 0x8000
    and     a7, a4, a7
    bnez    a7, Ldiv_done_up
    li      t6, 1
    ble     a6, t6, Ldiv_done_up
    slli    a4, a4, 1
    addi    a6, a6, -1
    j       Ldiv_norm_while
Ldiv_done_up:
    srli    a4, a4, 8

Ldiv_pack:
    andi    a4, a4, 0x7F
    li      a7, 0xFF
    blt     a6, a7, Ldiv_under
    li      a0, 0x7F80
    or      a0, a0, t6
    j       Ldiv_ep
Ldiv_under:
    blez    a6, Ldiv_signed_zero
    andi    a6, a6, 0xFF
    slli    a6, a6, 7
    or      a0, t6, a6
    or      a0, a0, a4
    j       Ldiv_ep
Ldiv_signed_zero:
    mv      a0, t6

Ldiv_ep:
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret


# ==================================================================================
# sqrt 函式
# t0: sign
# t1: exp
# t2: mant
#
#
#
#
#
# ==================================================================================

bf16_sqrt:

    addi sp, sp, -36
    sw ra, 32(sp)
    sw s0, 28(sp)
    sw s1, 24(sp)
    sw s2, 20(sp)
    sw s3, 16(sp)
    sw s4, 12(sp)
    sw s5, 8(sp)          # ★ 新增：保存 s5（用來取代原本錯用的 t7）

    mv      s0, a0          # s0 = a0 (input)

    # sign = (a>>15)&1, exp = (a>>7)&0xFF, mant = a & 0x7F
    srli    t0, s0, 15
    andi    t0, t0, 1          # t0 = sign
    srli    t1, s0, 7
    andi    t1, t1, 0xFF       # t1 = exp
    andi    t2, s0, 0x7F       # t2 = mant

    #exp==0xFF
    li      t3, 0xFF
    bne     t1, t3, sqrt_not_inf_nan   # exp != 0xFF → 走其他情況

    bnez    t2, sqrt_ret_a            # mant != 0 → NaN 原樣回傳 a0
    bnez    t0, sqrt_ret_nan          # mant == 0 且 sign != 0 (負無限) → 回傳 NaN
    j       sqrt_ret_a

sqrt_not_inf_nan:
    # !exp && !mant return ZERO
    bnez    t1, sqrt_not_zero_case
    bnez    t2, sqrt_not_zero_case
    li      a0, BF16_ZERO
    j       bf16_sqrt_end

sqrt_not_zero_case:
    # sign return NaN
    beqz    t0, sqrt_not_negative
    li      a0, BF16_NAN
    j       bf16_sqrt_end

sqrt_not_negative:
    # !exp return ZERO (denormal flush to zero)
    bnez    t1, sqrt_denorm_checked
    li      a0, BF16_ZERO
    j       bf16_sqrt_end

sqrt_denorm_checked:
    # e = exp - bias
    li      t3, BF16_EXP_BIAS
    sub     s1, t1, t3            # s1 = e = exp - bias

    # m = 0x80 | mant  (128 | mant)
    li      s2, 0x80
    or      s2, s2, t2          # s2 = m (uint32 in [128,255])

    # If(e & 1) { m<<=1; new_exp = ((e-1)>>1)+bias; } else { new_exp=(e>>1)+bias; }
    andi    t4, s1, 1          # t4 = e & 1
    beqz    t4, sqrt_even_exp  # e even
    
    slli    s2, s2, 1          # m <<= 1 (e odd)
    addi    t5, s1, -1         # t5 = e-1
    srai    t5, t5, 1          # t5 = (e-1)>>1
    addi    s3, t5, BF16_EXP_BIAS  # s3 = new_exp
    j       after_new_exp

#ELSE logic
sqrt_even_exp:
        srai    t5, s1, 1
        addi    s3, t5, BF16_EXP_BIAS  # s3 = new_exp


after_new_exp:
    #binay search
    #low=90, high=256, result=128
    li      s4, 90              # low
    li      t6, 256             # high
    li      t5, 128             # result

sqrt_bsearch_loop:
    # while (low <= high)
    bgt     s4, t6, sqrt_bsearch_done

    #mid=(low+high)>>1
    add     t0, s4, t6      # reuse t0 as mid/temp
    srai    t0, t0, 1       # t0 = mid

    # sq = (mid*mid)/128  ==> (mid*mid) >> 7
    # ---- 使用 16 步的位移加法乘法來計算 mid*mid）----
    # t2: acc, a2: multiplicand(mid), a3: multiplier(mid), s5: counter
    mv      a2, t0
    mv      a3, t0
    li      t2, 0
    li      s5, 16
sqrt_imul_loop:
    andi    a4, a3, 1
    beqz    a4, sqrt_imul_skip
    add     t2, t2, a2
sqrt_imul_skip:
    slli    a2, a2, 1
    srli    a3, a3, 1
    addi    s5, s5, -1
    bnez    s5, sqrt_imul_loop
    mv      t1, t2              # t1 = mid*mid
    # -----------------------------------------------------------------

    srli    t1, t1, 7           # t1 = sq

    # If (sq <= m) { result=mid; low=mid+1; } else { high=mid-1; }
    bgt     t1, s2, sq_gt_m
    mv      t5, t0                  # result = mid
    addi    s4, t0, 1               # low = mid+1
    j       sqrt_bsearch_loop

#ELSE logic
sq_gt_m:
        addi    t6, t0, -1              # high = mid-1
        j       sqrt_bsearch_loop

sqrt_bsearch_done:
    # result in t5, m in s2, new_exp in s3
    # Normalize:
    # If (result >= 256) { result>>=1; new_exp++; }
    li      t0, 256
    blt     t5, t0, chk_under_128
    srli    t5, t5, 1
    addi    s3, s3, 1
    j       sqrt_norm_done

chk_under_128:
    li      t0, 128
    bge     t5, t0, sqrt_norm_done

sqrt_norm_loop:
    # while (result < 128 && new_exp > 1) { result<<=1; new_exp--; }
    blt     t5, t0, sqrt_need_shift
    j       sqrt_norm_done

sqrt_need_shift:
    li      t1, 1
    ble     s3, t1, sqrt_norm_done
    slli    t5, t5, 1
    addi    s3, s3, -1
    j       sqrt_norm_loop

sqrt_norm_done:
    # new_mant = result & 0x7F
    andi    t0, t5, 0x7F       # t0 = new_mant

    # If (new_exp >= 0xFF) return +Inf
    li      t1, 0xFF
    blt     s3, t1, sqrt_chk_underflow
    li      a0, BF16_POS_INF
    j       bf16_sqrt_end

sqrt_chk_underflow:
    # If (new_exp <= 0) return ZERO
    blez    s3, sqrt_ret_zero
    # return (new_exp<<7) | new_mant
    slli    t1, s3, 7
    or      a0, t1, t0
    j       bf16_sqrt_end

sqrt_ret_zero:                           # return 0 (underflow)
    li      a0, BF16_ZERO
    j       bf16_sqrt_end

sqrt_ret_a:                              # 回傳 a（NaN 保留 payload/符號）
    mv      a0, s0
    j       bf16_sqrt_end

sqrt_ret_nan:                            # return 0x7FC0 (BF16_NAN)
    li      a0, 0x7FC0
    j       bf16_sqrt_end


bf16_sqrt_end:
    lw ra, 32(sp)
    lw s0, 28(sp)
    lw s1, 24(sp)
    lw s2, 20(sp)
    lw s3, 16(sp)
    lw s4, 12(sp)
    lw s5, 8(sp)           # ★ 還原 s5
    addi sp, sp, 36
    ret
