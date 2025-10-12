    .text
    .globl main

# =====================================================
# main
# =====================================================
main:
    # ---------------- Baseline ----------------
    la      s2, cases_in
    la      s3, cases_exp
    lw      s4, 0(s2)           # total n
    addi    s2, s2, 4
    addi    s3, s3, 4
    li      s0, 0               # i
    li      s1, 0               # pass_count

    la      a0, STR_BASELINE
    li      a7, 4
    ecall

Baseline_For:
    beq     s0, s4, Baseline_Summary

    lw      a0, 0(s2)           # x
    jal     ra, isPowerOfTwo_baseline
    mv      t1, a0              # got
    lw      t2, 0(s3)           # exp

    bne     t1, t2, Baseline_PrintFail

    la      a0, STR_PASS
    li      a7, 4
    ecall

    li      a7, 1               # x
    lw      a0, 0(s2)
    ecall

    la      a0, STR_ARROW
    li      a7, 4
    ecall

    li      a7, 1               # got
    mv      a0, t1
    ecall

    la      a0, STR_NL
    li      a7, 4
    ecall

    addi    s1, s1, 1
    j       Baseline_Cont

Baseline_PrintFail:
    la      a0, STR_FAIL
    li      a7, 4
    ecall

    li      a7, 1               # x
    lw      a0, 0(s2)
    ecall

    la      a0, STR_SPACE
    li      a7, 4
    ecall

    li      a7, 1               # exp
    mv      a0, t2
    ecall

    la      a0, STR_SPACE
    li      a7, 4
    ecall

    li      a7, 1               # got
    mv      a0, t1
    ecall

    la      a0, STR_NL
    li      a7, 4
    ecall

Baseline_Cont:
    addi    s0, s0, 1
    addi    s2, s2, 4
    addi    s3, s3, 4
    j       Baseline_For

Baseline_Summary:
    la      a0, STR_PASS_WORD
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, s1
    ecall

    la      a0, STR_SLASH
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, s4
    ecall

    la      a0, STR_NL2
    li      a7, 4
    ecall


    # ---------------- CLZ ----------------
    la      s2, cases_in
    la      s3, cases_exp
    lw      s4, 0(s2)           # total n
    addi    s2, s2, 4
    addi    s3, s3, 4
    li      s0, 0
    li      s1, 0

    la      a0, STR_CLZ
    li      a7, 4
    ecall

Clz_For:
    beq     s0, s4, Clz_Summary

    lw      a0, 0(s2)           # x
    jal     ra, isPowerOfTwo_clz
    mv      t1, a0              # got
    lw      t2, 0(s3)           # exp

    bne     t1, t2, Clz_PrintFail

    la      a0, STR_PASS
    li      a7, 4
    ecall

    li      a7, 1               # x
    lw      a0, 0(s2)
    ecall

    la      a0, STR_ARROW
    li      a7, 4
    ecall

    li      a7, 1               # got
    mv      a0, t1
    ecall

    la      a0, STR_NL
    li      a7, 4
    ecall

    addi    s1, s1, 1
    j       Clz_Cont

Clz_PrintFail:
    la      a0, STR_FAIL
    li      a7, 4
    ecall

    li      a7, 1               # x
    lw      a0, 0(s2)
    ecall

    la      a0, STR_SPACE
    li      a7, 4
    ecall

    li      a7, 1               # exp
    mv      a0, t2
    ecall

    la      a0, STR_SPACE
    li      a7, 4
    ecall

    li      a7, 1               # got
    mv      a0, t1
    ecall

    la      a0, STR_NL
    li      a7, 4
    ecall

Clz_Cont:
    addi    s0, s0, 1
    addi    s2, s2, 4
    addi    s3, s3, 4
    j       Clz_For

Clz_Summary:
    la      a0, STR_PASS_WORD
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, s1
    ecall

    la      a0, STR_SLASH
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, s4
    ecall

    la      a0, STR_NL2
    li      a7, 4
    ecall


    # ---------------- Optimized ----------------
    la      s2, cases_in
    la      s3, cases_exp
    lw      s4, 0(s2)           # total n
    addi    s2, s2, 4
    addi    s3, s3, 4
    li      s0, 0
    li      s1, 0

    la      a0, STR_OPTIMIZED
    li      a7, 4
    ecall

Optimized_For:
    beq     s0, s4, Optimized_Summary

    lw      a0, 0(s2)
    jal     ra, isPowerOfTwo_fast
    mv      t1, a0              # got
    lw      t2, 0(s3)           # exp

    bne     t1, t2, Optimized_PrintFail

    la      a0, STR_PASS
    li      a7, 4
    ecall

    li      a7, 1               # x
    lw      a0, 0(s2)
    ecall

    la      a0, STR_ARROW
    li      a7, 4
    ecall

    li      a7, 1               # got
    mv      a0, t1
    ecall

    la      a0, STR_NL
    li      a7, 4
    ecall

    addi    s1, s1, 1
    j       Optimized_Cont

Optimized_PrintFail:
    la      a0, STR_FAIL
    li      a7, 4
    ecall

    li      a7, 1               # x
    lw      a0, 0(s2)
    ecall

    la      a0, STR_SPACE
    li      a7, 4
    ecall

    li      a7, 1               # exp
    mv      a0, t2
    ecall

    la      a0, STR_SPACE
    li      a7, 4
    ecall

    li      a7, 1               # got
    mv      a0, t1
    ecall

    la      a0, STR_NL
    li      a7, 4
    ecall

Optimized_Cont:
    addi    s0, s0, 1
    addi    s2, s2, 4
    addi    s3, s3, 4
    j       Optimized_For

Optimized_Summary:
    la      a0, STR_PASS_WORD
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, s1
    ecall

    la      a0, STR_SLASH
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, s4
    ecall

    la      a0, STR_NL2
    li      a7, 4
    ecall

    # 程式結束
Halt:
    li      a7, 10
    ecall


# =====================================================
# Baseline
# =====================================================
    .globl isPowerOfTwo_baseline
isPowerOfTwo_baseline:
    beq     a0, x0, RetFalse_B

LoopEven_B:
    andi    t0, a0, 1
    bne     t0, x0, CheckOne_B
    srli    a0, a0, 1
    j       LoopEven_B

CheckOne_B:
    li      t0, 1
    beq     a0, t0, RetTrue_B
    j       RetFalse_B

RetTrue_B:
    li      a0, 1
    ret

RetFalse_B:
    mv      a0, x0
    ret


# =====================================================
# Optimized
# =====================================================
    .globl isPowerOfTwo_fast
isPowerOfTwo_fast:
    beq     a0, x0, RetFalse_F
    addi    t0, a0, -1
    and     t1, a0, t0
    bne     t1, x0, RetFalse_F
    li      a0, 1
    ret
RetFalse_F:
    mv      a0, x0
    ret


# =====================================================
# CLZ
# x>0 && clz(x) != clz(x-1)
# =====================================================
    .globl isPowerOfTwo_clz
isPowerOfTwo_clz:
    beq     a0, x0, RetFalse_C  # x==0 -> false

    addi    sp, sp, -16
    sw      ra, 12(sp)

    mv      t3, a0              #  x -> t3

    # clz(x) -> 存到 t5
    jal     ra, clz32           # a0 = clz(x)
    mv      t5, a0              # t5 = clz(x)

    # clz(x-1)
    addi    a0, t3, -1          # a0 = x-1
    jal     ra, clz32           # a0 = clz(x-1)

    # IF clz(x) != clz(x-1) -> power of two
    bne     a0, t5, Clz_True

    # IF clz(x) == clz(x-1) -> not the power of two
    mv      a0, x0
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

Clz_True:
    li      a0, 1
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

RetFalse_C:
    mv      a0, x0
    ret



# =====================================================
# clz32: count zeros
# =====================================================
    .globl clz32
clz32:
    beq     a0, x0, Clz_Return32

    li      t0, 0               # count
    li      t1, 16

Clz_Step:
    srl     t2, a0, t1          # t2 = a0 >> step
    bnez    t2, Clz_HasBits
    add     t0, t0, t1
    j       Clz_Next
Clz_HasBits:
    mv      a0, t2
Clz_Next:
    srli    t1, t1, 1           # step: 16,8,4,2,1
    bnez    t1, Clz_Step

    mv      a0, t0              #return
    ret

Clz_Return32:
    li      a0, 32
    ret


# =====================================================
# test data
# =====================================================
    .data

# test data（ 12 ）
cases_in:
    .word 12
    .word 0,1,2,3,4,5,8,16,31,32,1024,1025

cases_exp:
    .word 12
    .word 0,1,1,0,1,0,1,1,0,1,1,0

# 輸出字串
STR_PASS:       .string "PASS "
STR_FAIL:       .string "FAIL "
STR_PASS_WORD:  .string "PASS "
STR_SLASH:      .string "/"
STR_SPACE:      .string " "
STR_ARROW:      .string " -> "
STR_NL:         .string "\n"
STR_NL2:        .string "\n"
STR_BASELINE:   .string "Baseline\n"
STR_OPTIMIZED:  .string "Optimized\n"
STR_CLZ:        .string "CLZ\n"
