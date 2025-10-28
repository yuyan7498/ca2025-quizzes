    .text
    .globl main

# =====================================================
# main — Next Power of Two test
# =====================================================
main:
    li      s1, 0                       # pass_count = 0

    la      a0, STR_HDR                 # print header
    li      a7, 4
    ecall

    la      s2, npt_cases_in            # inputs ptr
    la      s3, npt_cases_exp           # expected ptr
    lw      s4, 0(s2)                   # N
    addi    s2, s2, 4
    addi    s3, s3, 4
    li      s0, 0                       # i = 0

Loop:
    beq     s0, s4, Summary

    lw      a0, 0(s2)                   # a0 = x
    mv      s5, a0                      # keep original x in s5 (callee won't clobber)
    jal     ra, next_power_of_two
    mv      t1, a0                      # got
    lw      t2, 0(s3)                   # exp

    bne     t1, t2, PrintFail

    # PASS
    la      a0, STR_PASS
    li      a7, 4
    ecall

    li      a7, 1                       # print x (from s5)
    mv      a0, s5
    ecall

    la      a0, STR_ARROW
    li      a7, 4
    ecall

    li      a7, 1                       # print got
    mv      a0, t1
    ecall

    la      a0, STR_NL
    li      a7, 4
    ecall

    addi    s1, s1, 1                   # pass_count++
    j       Cont

PrintFail:
    la      a0, STR_FAIL
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, s5                      # print x (from s5)
    ecall

    la      a0, STR_ARROW
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, t1                      # print got
    ecall

    la      a0, STR_NL
    li      a7, 4
    ecall

Cont:
    addi    s0, s0, 1
    addi    s2, s2, 4
    addi    s3, s3, 4
    j       Loop

Summary:
    la      a0, STR_PASS_WORD
    li      a7, 4
    ecall

    li      a7, 1
    mv      a0, s1
    ecall

    la      a0, STR_SLASH
    li      a7, 4
    ecall

    li      a7, 1                      # print N_TOTAL
    la      a0, N_TOTAL
    lw      a0, 0(a0)
    ecall

    la      a0, STR_NL2
    li      a7, 4
    ecall

    li      a7, 10
    ecall


# =====================================================
# next_power_of_two(x)
# a0: x  -> a0: next pow2 >= x
# =====================================================
    .globl next_power_of_two
next_power_of_two:
    beq     a0, x0, NPT_ret1           # if x==0 -> 1

    mv      t3, ra                     # save caller's ra
    addi    a0, a0, -1                 # a0 = x - 1
    jal     ra, clz32                  # a0 = clz(x-1)
    mv      ra, t3                     # restore ra

    li      t0, 32
    sub     t0, t0, a0                 # t0 = 32 - clz(x-1)
    li      a0, 1
    sll     a0, a0, t0                 # a0 = 1 << (32 - clz(x-1))
    ret
NPT_ret1:
    li      a0, 1
    ret


# =====================================================
# clz32(x)
# a0: x  -> a0: clz(x)
# =====================================================
    .globl clz32
clz32:
    li      t0, 32                     # n = 32
    li      t1, 16                     # c = 16
CLZ_loop:
    srl     t2, a0, t1                 # y = x >> c
    beq     t2, x0, CLZ_skip
    sub     t0, t0, t1                 # n -= c
    mv      a0, t2                     # x = y
CLZ_skip:
    srli    t1, t1, 1                  # c >>= 1
    bnez    t1, CLZ_loop
    sub     a0, t0, a0                 # return n - x
    ret


# =====================================================
# Data
# =====================================================
    .data
N_TOTAL:        .word 8
npt_cases_in:
    .word 8
    .word 0,1,2,3,5,9,17,33

npt_cases_exp:
    .word 8
    .word 1,1,2,4,8,16,32,64

STR_HDR:        .string "=== Next Power of Two ===\n"
STR_PASS:       .string "PASS "
STR_FAIL:       .string "FAIL "
STR_PASS_WORD:  .string "PASS "
STR_SLASH:      .string "/"
STR_ARROW:      .string " -> "
STR_NL:         .string "\n"
STR_NL2:        .string "\n"
