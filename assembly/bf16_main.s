    .text
    .globl main

main:
    # ----------------------------
    # Section A: isnan / isinf / iszero
    # ----------------------------
    # A1: bf16_isnan(0x7FC1) -> 1
    li      a0, 0x7FC1
    jal     ra, bf16_isnan
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # A2: bf16_isnan(0x7F80) -> 0
    li      a0, 0x7F80
    jal     ra, bf16_isnan
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # A3: bf16_isinf(0x7F80) -> 1
    li      a0, 0x7F80
    jal     ra, bf16_isinf
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # A4: bf16_iszero(0x0000) -> 1
    li      a0, 0x0000
    jal     ra, bf16_iszero
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # A5: bf16_iszero(0x3F80) -> 0
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
    # B1: NaN 0x7FC00000 -> 0x7FC0
    li      a0, 0x7FC00000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # B2: +Inf 0x7F800000 -> 0x7F80
    li      a0, 0x7F800000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # B3: 1.0 0x3F800000 -> 0x3F80
    li      a0, 0x3F800000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # B4: 0.5 0x3F000000 -> 0x3F00
    li      a0, 0x3F000000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # B5: tie-even (high16 even) 0x3F808000 -> no round-up
    li      a0, 0x3F808000
    jal     ra, f32_to_bf16
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # B6: tie-even (high16 odd) 0x3F818000 -> round-up to even
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
    # C1: 0x7FC0 -> 0x7FC00000
    li      a0, 0x7FC0
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # C2: 0x7F80 -> 0x7F800000
    li      a0, 0x7F80
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # C3: 0x3F80 -> 0x3F800000
    li      a0, 0x3F80
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # C4: 0x3F00 -> 0x3F000000
    li      a0, 0x3F00
    jal     ra, bf16_to_f32
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # C5: 0x0000 -> 0x00000000
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
    # D1: 1.0 + 0.5 -> 0x3FC0 (16320)
    li      a0, 0x3F80
    li      a1, 0x3F00
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # D2: 1.0 + (-1.0) -> 0x0000
    li      a0, 0x3F80
    li      a1, 0xBF80
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # D3: 1.0 + 2^-9 (diff>8) -> 0x3F80 (16256)
    li      a0, 0x3F80
    li      a1, 0x3B00
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # D4: +Inf + finite -> +Inf (0x7F80)
    li      a0, 0x7F80
    li      a1, 0x3F80
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # D5: +Inf + -Inf -> NaN (0x7FC0)
    li      a0, 0x7F80
    li      a1, 0xFF80
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # D6: NaN + 1.0 -> NaN (回傳 a 的 NaN)
    li      a0, 0x7FC1
    li      a1, 0x3F80
    jal     ra, bf16_add
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # D7(sub): 1.0 - 0.5 -> 0x3F00 (16128)
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
    # E1: 1.5 * (-0.5) -> 0xBF40 (48960)
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
    # F1: 1.0 / 2.0 -> 0x3F00 (16128)
    li      a0, 0x3F80
    li      a1, 0x4000
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # F2: 1.0 / 0.0 -> +Inf (0x7F80)
    li      a0, 0x3F80
    li      a1, 0x0000
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # F3: 0.0 / 2.0 -> 0x0000
    li      a0, 0x0000
    li      a1, 0x4000
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # F4: +Inf / 2.0 -> +Inf
    li      a0, 0x7F80
    li      a1, 0x4000
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # F5: NaN / 1.0 -> NaN (回傳 a 的 NaN)
    li      a0, 0x7FC0
    li      a1, 0x3F80
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # F6: 1.0 / NaN -> NaN (回傳 b 的 NaN)
    li      a0, 0x3F80
    li      a1, 0x7FC0
    jal     ra, bf16_div
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # 結束
    li      a7, 10
    ecall


# ------------------------------------------------------------
# bool bf16_isnan(uint16_t bits)
# // C: return ((bits & 0x7F80)==0x7F80) && (bits & 0x007F);
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# bool bf16_isinf(uint16_t bits)
# // C: return ((bits & 0x7F80)==0x7F80) && !(bits & 0x007F);
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# bool bf16_iszero(uint16_t bits)
# // C: return !(bits & 0x7FFF);
# ------------------------------------------------------------
bf16_iszero:
    li      t0, 0x7FFF
    and     t0, a0, t0
    bne     t0, x0, Lzero_false
    li      a0, 1
    ret
Lzero_false:
    mv      a0, x0
    ret

# ------------------------------------------------------------
# bf16_t f32_to_bf16(uint32_t f32bits)
# // C:
# // if (exp==0xFF) return high16(f32bits);
# // f32bits += ((high16&1) + 0x7FFF); return high16(f32bits);
# ------------------------------------------------------------
f32_to_bf16:
    # // C: uint8_t exp = (f32bits>>23)&0xFF;
    srli    t0, a0, 23
    andi    t0, t0, 0x0FF
    li      t1, 0x0FF
    beq     t0, t1, Lfte_special

    # // C: RNE
    srli    t2, a0, 16
    andi    t2, t2, 1
    li      t3, 0x7FFF
    add     t2, t2, t3
    add     a0, a0, t2

    # // C: return high16
    srli    a0, a0, 16
    ret
Lfte_special:
    srli    a0, a0, 16
    li      t0, 0xFFFF
    and     a0, a0, t0
    ret

# ------------------------------------------------------------
# uint32_t bf16_to_f32(uint16_t bits)
# // C: return ((uint32_t)bits)<<16;
# ------------------------------------------------------------
bf16_to_f32:
    li      t0, 0xFFFF
    and     a0, a0, t0
    slli    a0, a0, 16
    ret

# ------------------------------------------------------------
# bf16_add(a0=a.bits, a1=b.bits) -> a0
# // C: 依 C 版本流程：特殊值 → 對齊 → 同號加/異號減 → 規格化 → pack
# ------------------------------------------------------------
bf16_add:
    # // C: 取 sign/exp/mant
    srli    t0, a0, 15
    andi    t0, t0, 1
    srli    t1, a1, 15
    andi    t1, t1, 1
    srli    t2, a0, 7
    andi    t2, t2, 0xFF
    srli    t3, a1, 7
    andi    t3, t3, 0xFF
    andi    t4, a0, 0x7F
    andi    t5, a1, 0x7F

    li      t6, 0xFF
    bne     t2, t6, 1f               # // C: if (exp_a==0xFF)
    beq     t4, x0, La_is_inf
    mv      a0, a0                    # // C: NaN → return a
    ret
La_is_inf:
    bne     t3, t6, Lret_a
    beq     t5, x0, 0f                # b Inf?
    mv      a0, a1                    # b NaN → return b
    ret
0:
    bne     t0, t1, Lret_NaN          # +Inf + -Inf → NaN
    mv      a0, a1                    # 同號 Inf → b(也是Inf)
    ret
Lret_NaN:
    li      a0, 0x7FC0
    ret
Lret_a:
    mv      a0, a0
    ret

1:  # // C: if (exp_b==0xFF) return b;
    bne     t3, t6, 2f
    mv      a0, a1
    ret

2:  # // C: if (a==0) return b;
    beq     t2, x0, 3f
    j       4f
3:
    beq     t4, x0, Lret_b
    j       4f
Lret_b:
    mv      a0, a1
    ret

4:  # // C: if (b==0) return a;
    beq     t3, x0, 5f
    j       6f
5:
    beq     t5, x0, Lret_a2
    j       6f
Lret_a2:
    mv      a0, a0
    ret

6:  # // C: 規格化補隱含位
    beq     t2, x0, 7f
    ori     t4, t4, 0x80
7:
    beq     t3, x0, 8f
    ori     t5, t5, 0x80
8:
    # // C: 指數對齊
    sub     a2, t2, t3
    beq     a2, x0, 9f
    blt     x0, a2, 10f

    # exp_diff<0 → b 大
    neg     a3, a2
    li      t6, 8
    blt     t6, a3, Lret_b
    srl     t4, t4, a3
    mv      t6, t3
    j       11f
10: # a 大
    li      t6, 8
    blt     t6, a2, Lret_a2
    srl     t5, t5, a2
    mv      t6, t2
    j       11f
9:
    mv      t6, t2

11: # // C: 同號/異號
    bne     t0, t1, Ldiff_sign

    # // C: 同號 → mant 相加、檢查進位
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
    # // C: 異號 → 大減小，取大者符號
    bge     t4, t5, 12f
    sub     a4, t5, t4
    mv      a3, t1
    j       13f
12:
    sub     a4, t4, t5
    mv      a3, t0
13:
    beq     a4, x0, Lret_zero

14: # // C: 規格化：while(!(mant&0x80)){mant<<=1; if(--exp<=0) return 0;}
    andi    a5, a4, 0x80
    bne     a5, x0, Lpack
    slli    a4, a4, 1
    addi    t6, t6, -1
    blt     x0, t6, 14b           # (exp > 0) 用 blt x0,t6
Lret_zero:
    mv      a0, x0
    ret

Lpack:
    # // C: pack (sign<<15)|((exp&0xFF)<<7)|(mant&0x7F)
    slli    a3, a3, 15
    andi    a5, t6, 0xFF
    slli    a5, a5, 7
    andi    a4, a4, 0x7F
    or      a3, a3, a5
    or      a0, a3, a4
    ret

# ------------------------------------------------------------
# bf16_sub(a,b) = bf16_add(a, flip_sign(b))
# // C: b.bits ^= 0x8000; return bf16_add(a,b);
# ------------------------------------------------------------
bf16_sub:
    li      t0, 0x8000
    xor     a1, a1, t0
    j       bf16_add

# ------------------------------------------------------------
# bf16_mul(a0=a.bits, a1=b.bits) -> a0
# // C: 特殊值 → normalize → 8x8 位元乘法 → 規格化、溢位/下溢 → pack
# ------------------------------------------------------------
bf16_mul:
    # // C: 取 sign/exp/mant
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
    xor     t2, t0, t1                 # result_sign

    # // C: a Inf/NaN
    li      a2, 0xFF
    bne     t3, a2, Lmul_chk_b
    bnez    t5, Lmul_ret_a            # NaN → a
    beqz    t4, Lmul_inf_x_zero_chk
    j       Lmul_ret_sign_inf
Lmul_inf_x_zero_chk:
    beqz    t6, Lmul_ret_nan
    j       Lmul_ret_sign_inf

Lmul_chk_b:
    bne     t4, a2, Lmul_check_zero
    bnez    t6, Lmul_ret_b            # NaN → b
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
    li      a4, 0                      # exp_adjust=0
    beqz    t3, Lmul_norm_a_sub
    ori     t5, t5, 0x80               # a 正規→補隱含1
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
    mv      a3, zero                   # result_mant=0
    mv      a5, t6                     # multiplier
    mv      a2, t5                     # multiplicand
    li      t0, 8                      # 8 位元乘加
Lmul_loop:
    andi    t1, a5, 1
    beqz    t1, Lmul_skip_add
    add     a3, a3, a2
Lmul_skip_add:
    slli    a2, a2, 1
    srli    a5, a5, 1
    addi    t0, t0, -1
    bnez    t0, Lmul_loop

    # // C: result_exp = exp_a + exp_b - 127 + exp_adjust
    add     a2, t3, t4
    add     a2, a2, a4
    addi    a2, a2, -127

    # // C: 規格化尾數
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

    # // C: 溢位
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
    sub     t1, t1, a2               # shift = 1 - exp
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

# ------------------------------------------------------------
# bf16_div(a0=a.bits, a1=b.bits) -> a0
# // C: 特殊值 → 16步長整數除法 → 規格化 → 溢位/下溢 → pack
# ------------------------------------------------------------
    .globl bf16_div
bf16_div:
    addi    sp, sp, -16
    sw      ra, 12(sp)

    # // C: 解析 sign/exp/mant
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

    xor     t6, t0, t1               # result_sign
    slli    t6, t6, 15

    # // C: if (exp_b==0xFF)
    li      a4, 0xFF
    bne     t3, a4, Ldiv_not_b_inf
    bnez    t5, Ldiv_return_b       # NaN
    # b is Inf
    li      a5, 0xFF
    bne     t2, a5, Ldiv_b_inf_zero
    bnez    t4, Ldiv_b_inf_zero     # a NaN payload → 擬合 0 路徑
    li      a0, 0x7FC0               # Inf/Inf = NaN
    j       Ldiv_ep
Ldiv_b_inf_zero:
    mv      a0, t6                   # ±0
    j       Ldiv_ep

Ldiv_not_b_inf:
    # // C: if (b==0)
    beqz    t3, Ldiv_chk_b_mant
    j       Ldiv_chk_a_inf
Ldiv_chk_b_mant:
    bnez    t5, Ldiv_chk_a_inf
    # b == 0
    beqz    t2, Ldiv_both_zero
    j       Ldiv_by_zero_ret_inf
Ldiv_both_zero:
    beqz    t4, Ldiv_return_nan     # 0/0 = NaN
Ldiv_by_zero_ret_inf:
    li      a0, 0x7F80
    or      a0, a0, t6
    j       Ldiv_ep

Ldiv_chk_a_inf:
    li      a4, 0xFF
    bne     t2, a4, Ldiv_a_not_inf
    bnez    t4, Ldiv_return_a       # a=NaN → a
    li      a0, 0x7F80               # a=Inf → ±Inf
    or      a0, a0, t6
    j       Ldiv_ep

Ldiv_a_not_inf:
    beqz    t2, Ldiv_a_zero_path
    j       Ldiv_normals
Ldiv_a_zero_path:
    bnez    t4, Ldiv_normals
    mv      a0, t6                   # 0 / 非零 = ±0
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

# // C: 一般路徑：補隱含位
Ldiv_normals:
    beqz    t2, Ldiv_no_imp_a
    ori     t4, t4, 0x80
Ldiv_no_imp_a:
    beqz    t3, Ldiv_no_imp_b
    ori     t5, t5, 0x80
Ldiv_no_imp_b:

    # // C: 整數除法 (16步長)
    slli    a2, t4, 15              # dividend
    mv      a3, t5                  # divisor
    li      a4, 0                   # quotient
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

    # // C: result_exp = exp_a - exp_b + 127 (+subnorm調整)
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
    ble     a6, t6, Ldiv_done_up   # 避免 exp 掉到 0 以下
    slli    a4, a4, 1
    addi    a6, a6, -1
    j       Ldiv_norm_while
Ldiv_done_up:
    srli    a4, a4, 8

Ldiv_pack:
    andi    a4, a4, 0x7F
    li      a7, 0xFF
    blt     a6, a7, Ldiv_under
    li      a0, 0x7F80               # overflow → ±Inf
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
