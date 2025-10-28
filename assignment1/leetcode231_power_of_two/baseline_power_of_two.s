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