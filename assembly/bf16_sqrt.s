    .text
    .globl main
    .globl bf16_sqrt

# =========================================
# 常數（bf16）
# =========================================
    .equ BF16_SIGN_MASK, 0x8000
    .equ BF16_EXP_MASK,  0x7F80
    .equ BF16_MANT_MASK, 0x007F
    .equ BF16_EXP_BIAS,  127

    .equ BF16_POS_INF,   0x7F80
    .equ BF16_NEG_INF,   0xFF80
    .equ BF16_NAN,       0x7FC0
    .equ BF16_ZERO,      0x0000

# =========================================
# sqrt 函式
# t0: sign
# t1: exp
# t2: mant
# =========================================

bf16_sqrt:

    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4, 8(sp)

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
    #while(low<high)
    bge     s4, t6, sqrt_bsearch_done

    #mid=(low+high)>>1
    add     t0, s4, t6      # reuse t0 as mid/temp
    srai    t0, t0, 1       # t0 = mid

    # sq = (mid*mid)/128  ==> (mid*mid) >> 7
    mul     t1, t0, t0          # t1 = mid*mid
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
    ble     s3, t1, norm_done
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
    blez    s3, ret_zero
    # return (new_exp<<7) | new_mant
    slli    t1, s3, 7
    or      a0, t1, t0
    j       bf16_sqrt_end

sqrt_ret_a:                              # 回傳 a（NaN 保留 payload/符號）
    mv      a0, s0
    j       bf16_sqrt_end

sqrt_ret_nan:                            # return 0x7FC0 (BF16_NAN)
    li      a0, 0x7FC0
    j       bf16_sqrt_end


bf16_sqrt_end:
    lw ra, 28(sp)
    lw s0, 24(sp)
    lw s1, 20(sp)
    lw s2, 16(sp)
    lw s3, 12(sp)
    lw s4, 8(sp)
    addi sp, sp, 32
    ret