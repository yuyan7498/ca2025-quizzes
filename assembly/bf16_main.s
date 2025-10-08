    .data
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
# 測資
# =========================================
# =========================================
# Section A
# =========================================
isnan_input:
    .word   3
    .word   0x7FC1
    .word   0x7F80
    .word   0x7FC1

isnan_exp:
    .word   1
    .word   0
    .word   1

isinf_input:
    .word   3
    .word   0x7F80
    .word   0x7FC1
    .word   0x7F80

isinf_exp:
    .word   1
    .word   0
    .word   1

iszero_input:
    .word   2
    .word   0x0000
    .word   0x3F80

iszero_exp:
    .word   1
    .word   0

# =========================================
# Section B
# =========================================
f32_to_bf16_input:
    .word   0x7FC00000
    .word   0x7F800000
    .word   0x3F800000
    .word   0x3F000000
    .word   0x3F808000
    .word   0x3F818000

f32_to_bf16_exp:
    .word   32704     # 0x7F80
    .word   32640     # 0x7F40
    .word   16256     # 0x3F80
    .word   16128     # 0x3F00
    .word   16256     # tie-even (even)
    .word   16258     # tie-even (odd)

# =========================================
# Section C
# =========================================
bf16_to_f32_input:
    .word   0x7FC0
    .word   0x7F80
    .word   0x3F80
    .word   0x3F00
    .word   0x0000

bf16_to_f32_exp:
    .word   2143289344
    .word   2139095040
    .word   1065353216
    .word   1056964608
    .word   0

# =========================================
# Section D
# =========================================
bf16_add_input:
    .word   0x3F80, 0x3F00   # 1.0 + 0.5
    .word   0x3F80, 0xBF80   # 1.0 + (-1.0)
    .word   0x3F80, 0x3B00   # 1.0 + small
    .word   0x7F80, 0x3F80   # Inf + 1.0
    .word   0x7F80, 0xFF80   # +Inf + -Inf
    .word   0x7FC1, 0x3F80   # NaN + 1.0

bf16_add_exp:
    .word   16320
    .word   0
    .word   16256
    .word   32640
    .word   32704
    .word   32705

bf16_sub_input:
    .word   0x3F80, 0x3F00   # 1.0 - 0.5

bf16_sub_exp:
    .word   16128

# =========================================
# Section E
# =========================================
bf16_mul_input:
    .word   0x3FC0, 0xBF00   # 1.5 * -0.5

bf16_mul_exp:
    .word   48960

# =========================================
# Section F
# =========================================
bf16_div_input:
    .word   0x3F80, 0x4000   # 1 / 2
    .word   0x3F80, 0x0000   # 1 / 0
    .word   0x0000, 0x4000   # 0 / 2
    .word   0x7F80, 0x4000   # Inf / 2
    .word   0x7FC0, 0x3F80   # NaN / 1
    .word   0x3F80, 0x7FC0   # 1 / NaN

bf16_div_exp:
    .word   16128
    .word   32640
    .word   0
    .word   32640
    .word   32704
    .word   32704

# =========================================
# Section G
# =========================================
bf16_sqrt_input:
    .word   0x3F80   # sqrt(1.0)
    .word   0x3E80   # sqrt(0.25)
    .word   0x7F80   # sqrt(+Inf)
    .word   0x7FC1   # sqrt(NaN)
    .word   0x0000   # sqrt(0)
    .word   0xBF80   # sqrt(-1.0)

bf16_sqrt_exp:
    .word   16256
    .word   16128
    .word   32640
    .word   32705
    .word   0
    .word   32704


input_msg:
    .string "input:"
exp_msg:
    .string "exp:"
got_msg:
    .string "got:"
pass_msg:
    .string "Pass"
fail_msg:
    .string "FAIL"


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
# main: 測資整合（A~G）
# =========================================

# 1
# 0
# 1
# 1
# 0
# 32704
# 32640
# 16256
# 16128
# 16256
# 16258
# 2143289344
# 2139095040
# 1065353216
# 1056964608
# 0
# 16320
# 0
# 16256
# 32640
# 32704
# 32705
# 16128
# 48960
# 16128
# 32640
# 0
# 32640
# 32704
# 32704
# 16256
# 16128
# 32640
# 32705
# 0
# 32704

# Program exited with code: 0

main:

    # =========================================
    # Section A1: bf16_isnan  （帶 count）
    # =========================================
    la      t0, isnan_input        # t0 = input base
    lw      t1, 0(t0)              # t1 = count
    addi    t0, t0, 4              # t0 -> first data
    la      t3, isnan_exp          # t3 = exp base
    li      t2, 0                  # i = 0

A1_loop:
    bge     t2, t1, A1_done

    lw      t4, 0(t0)              # input
    lw      t6, 0(t3)              # exp

    # print "input:" value
    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    # save caller-saved & call bf16_isnan(a0=input)
    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    jal     ra, bf16_isnan
    mv      t5, a0                 # got

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    # print "exp:" exp " got:" got
    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32                 # ' '
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, A1_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       A1_after
A1_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
A1_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 4
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       A1_loop

A1_done:

    # =========================================
    # Section A2: bf16_isinf  （帶 count）
    # =========================================
    la      t0, isinf_input
    lw      t1, 0(t0)
    addi    t0, t0, 4
    la      t3, isinf_exp
    li      t2, 0

A2_loop:
    bge     t2, t1, A2_done

    lw      t4, 0(t0)
    lw      t6, 0(t3)

    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    jal     ra, bf16_isinf
    mv      t5, a0

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, A2_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       A2_after
A2_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
A2_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 4
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       A2_loop

A2_done:

    # =========================================
    # Section A3: bf16_iszero  （帶 count）
    # =========================================
    la      t0, iszero_input
    lw      t1, 0(t0)
    addi    t0, t0, 4
    la      t3, iszero_exp
    li      t2, 0

A3_loop:
    bge     t2, t1, A3_done

    lw      t4, 0(t0)
    lw      t6, 0(t3)

    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    jal     ra, bf16_iszero
    mv      t5, a0

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, A3_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       A3_after
A3_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
A3_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 4
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       A3_loop

A3_done:

    # =========================================
    # Section B: f32_to_bf16  （N=6）
    # =========================================
    la      t0, f32_to_bf16_input
    la      t3, f32_to_bf16_exp
    li      t1, 6                  # N
    li      t2, 0

B_loop:
    bge     t2, t1, B_done

    lw      t4, 0(t0)              # input f32 bits
    lw      t6, 0(t3)              # exp bf16

    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    jal     ra, f32_to_bf16
    mv      t5, a0

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, B_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       B_after
B_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
B_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 4
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       B_loop

B_done:

    # =========================================
    # Section C: bf16_to_f32 （N=5）
    # =========================================
    la      t0, bf16_to_f32_input
    la      t3, bf16_to_f32_exp
    li      t1, 5
    li      t2, 0

C_loop:
    bge     t2, t1, C_done

    lw      t4, 0(t0)
    lw      t6, 0(t3)

    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    jal     ra, bf16_to_f32
    mv      t5, a0

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, C_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       C_after
C_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
C_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 4
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       C_loop

C_done:

    # =========================================
    # Section D: bf16_add （N=6, 成對）
    # =========================================
    la      t0, bf16_add_input
    la      t3, bf16_add_exp
    li      t1, 6
    li      t2, 0

D_add_loop:
    bge     t2, t1, D_add_done

    lw      t4, 0(t0)              # a
    lw      t5, 4(t0)              # b
    lw      t6, 0(t3)              # exp

    # print input: "input:" a ' ' b
    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    mv      a1, t5
    jal     ra, bf16_add
    mv      t5, a0                  # got

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, D_add_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       D_add_after
D_add_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
D_add_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 8
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       D_add_loop

D_add_done:

    # =========================================
    # Section D-Sub: bf16_sub （N=1, 成對）
    # =========================================
    la      t0, bf16_sub_input
    la      t3, bf16_sub_exp
    li      t1, 1
    li      t2, 0

D_sub_loop:
    bge     t2, t1, D_sub_done

    lw      t4, 0(t0)
    lw      t5, 4(t0)
    lw      t6, 0(t3)

    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    mv      a1, t5
    jal     ra, bf16_sub
    mv      t5, a0

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, D_sub_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       D_sub_after
D_sub_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
D_sub_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 8
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       D_sub_loop

D_sub_done:

    # =========================================
    # Section E: bf16_mul （N=1, 成對）
    # =========================================
    la      t0, bf16_mul_input
    la      t3, bf16_mul_exp
    li      t1, 1
    li      t2, 0

E_loop:
    bge     t2, t1, E_done

    lw      t4, 0(t0)
    lw      t5, 4(t0)
    lw      t6, 0(t3)

    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    mv      a1, t5
    jal     ra, bf16_mul
    mv      t5, a0

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, E_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       E_after
E_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
E_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 8
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       E_loop

E_done:

    # =========================================
    # Section F: bf16_div （N=6, 成對）
    # =========================================
    la      t0, bf16_div_input
    la      t3, bf16_div_exp
    li      t1, 6
    li      t2, 0

F_loop:
    bge     t2, t1, F_done

    lw      t4, 0(t0)
    lw      t5, 4(t0)
    lw      t6, 0(t3)

    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    mv      a1, t5
    jal     ra, bf16_div
    mv      t5, a0

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, F_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       F_after
F_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
F_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 8
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       F_loop

F_done:

    # =========================================
    # Section G: bf16_sqrt （N=6，單一輸入）
    # =========================================
    la      t0, bf16_sqrt_input
    la      t3, bf16_sqrt_exp
    li      t1, 6
    li      t2, 0

G_loop:
    bge     t2, t1, G_done

    lw      t4, 0(t0)
    lw      t6, 0(t3)

    la      a0, input_msg
    li      a7, 4
    ecall
    mv      a0, t4
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    addi    sp, sp, -20
    sw      t0, 0(sp)
    sw      t1, 4(sp)
    sw      t2, 8(sp)
    sw      t3, 12(sp)
    sw      ra, 16(sp)

    mv      a0, t4
    jal     ra, bf16_sqrt
    mv      t5, a0

    lw      t0, 0(sp)
    lw      t1, 4(sp)
    lw      t2, 8(sp)
    lw      t3, 12(sp)
    lw      ra, 16(sp)
    addi    sp, sp, 20

    la      a0, exp_msg
    li      a7, 4
    ecall
    mv      a0, t6
    li      a7, 1
    ecall
    li      a0, 32
    li      a7, 11
    ecall
    la      a0, got_msg
    li      a7, 4
    ecall
    mv      a0, t5
    li      a7, 1
    ecall
    li      a0, 10
    li      a7, 11
    ecall

    bne     t5, t6, G_fail
    la      a0, pass_msg
    li      a7, 4
    ecall
    j       G_after
G_fail:
    la      a0, fail_msg
    li      a7, 4
    ecall
G_after:
    li      a0, 10
    li      a7, 11
    ecall

    addi    t0, t0, 4
    addi    t3, t3, 4
    addi    t2, t2, 1
    j       G_loop

G_done:
    li      a0, 0
    li      a7, 10                 # 程式結束（只在這裡用一次）
    ecall


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
    #   If (exp_a == 0xFF) {
    #       If (mant_a) return a;                 
    #       If (exp_b == 0xFF)
    #           return (mant_b || sign_a == sign_b) ? b 
    #                  : BF16_NAN();                 
    #       return a;
    #   }
    li      t6, 0xFF
    bne     t2, t6, 1f      # if exp_a != 0xFF skip

    beq     t4, x0, La_is_inf       # mant_a==0 → a 是 Inf
    mv      a0, a0              # mant_a!=0 → a 
    ret
La_is_inf:
    bne     t3, t6, Lret_a      # exp_b!=0xFF →  a
    beq     t5, x0, 0f          # mant_b==0 →  Inf
    mv      a0, a1              # mant_b!=0 → NaN， b
    ret
0:  # a=Inf, b=Inf
    bne     t0, t1, Lret_NaN    # sign_a!=sign_b → NaN 
    mv      a0, a1              # sign_a==sign_b → Inf
    ret
Lret_NaN:
    li      a0, BF16_NAN          # BF16_NAN()
    ret
Lret_a:
    mv      a0, a0
    ret

    #   If (exp_b == 0xFF) return b;
1:
    bne     t3, t6, 2f
    mv      a0, a1
    ret

    #   If (!exp_a && !mant_a) return b;
2:
    beq     t2, x0, 3f
    j       4f
3:
    beq     t4, x0, Lret_b
    j       4f
Lret_b:
    mv      a0, a1
    ret

    #   If (!exp_b && !mant_b) return a;
4:
    beq     t3, x0, 5f
    j       6f
5:
    beq     t5, x0, Lret_a2
    j       6f
Lret_a2:
    mv      a0, a0
    ret

    #   If (exp_a) mant_a |= 0x80;
    #   If (exp_b) mant_b |= 0x80;
6:
    beq     t2, x0, 7f
    ori     t4, t4, 0x80    # mant_a |= 0x80
7:
    beq     t3, x0, 8f
    ori     t5, t5, 0x80    # mant_b |= 0x80
8:

    # ---- 指數對齊 ----
    #   int16_t exp_diff = exp_a - exp_b;
    #   If (exp_diff > 0) {
    #       result_exp = exp_a;
    #       If (exp_diff > 8) return a;
    #       mant_b >>= exp_diff;
    #   } else if (exp_diff < 0) {
    #       result_exp = exp_b;
    #       If (exp_diff < -8) return b;
    #       mant_a >>= -exp_diff;
    #   } else {
    #       result_exp = exp_a;
    #   }
    sub     a2, t2, t3      # a2 = exp_a - exp_b
    beq     a2, x0, 9f      # if exp_a == exp_b skip
    blt     x0, a2, 10f     # if exp_a < exp_b

    # exp_diff < 0（exp_a < exp_b）
    neg     a3, a2
    li      t6, 8
    blt     t6, a3, Lret_b  # if -exp_diff > 8 → 回 b
    srl     t4, t4, a3      # mant_a >>= -exp_diff
    mv      t6, t3          # result_exp = exp_b
    j       11f
10:
    # exp_diff > 0（exp_a > exp_b）
    li      t6, 8
    blt     t6, a2, Lret_a2 # if  exp_diff > 8 → 回 a
    srl     t5, t5, a2      # mant_b >>=  exp_diff
    mv      t6, t2          # result_exp = exp_a
    j       11f
9:
    # exp_diff == 0
    mv      t6, t2          # result_exp = exp_a

11:
    # ---- 同號/異號處理 ----
    #   If (sign_a == sign_b) {
    #       result_sign = sign_a;
    #       result_mant = (uint32_t)mant_a + mant_b;
    #       If (result_mant & 0x100) {
    #           result_mant >>= 1;
    #           If (++result_exp >= 0xFF)
    #               return { .bits = (result_sign<<15) | 0x7F80 }; // 溢位到 Inf
    #       }
    #   }
    #   ELSE {
    #       If (mant_a >= mant_b) { result_sign = sign_a; result_mant = mant_a - mant_b; }
    #       ELSE { result_sign = sign_b; result_mant = mant_b - mant_a; }
    #       If (!result_mant) return BF16_ZERO();
    #       while (!(result_mant & 0x80)) {
    #           result_mant <<= 1;
    #           If (--result_exp <= 0) return BF16_ZERO();
    #       }
    #   }
    bne     t0, t1, Ldiff_sign

    # 同號相加路徑
    add     a4, t4, t5      # result_mant = mant_a + mant_b
    mv      a3, t0          # result_sign = sign_a
    andi    a5, a4, 0x100   
    beq     a5, x0, Lpack   
    srli    a4, a4, 1    
    addi    t6, t6, 1       # result_exp++
    li      a5, 0xFF
    blt     t6, a5, Lpack 
    slli    a3, a3, 15
    li      a5, 0x7F80      # 溢位：回傳 ±Inf
    or      a0, a3, a5
    ret

Ldiff_sign:
    bge     t4, t5, 12f
    sub     a4, t5, t4      # result_mant = mant_b - mant_a
    mv      a3, t1          # result_sign = sign_b
    j       13f
12:
    sub     a4, t4, t5      # result_mant = mant_a - mant_b
    mv      a3, t0          # result_sign = sign_a
13:
    beq     a4, x0, Lret_zero   # if (!result_mant) return 0

14:
    # while (!(result_mant & 0x80)) { result_mant <<= 1; if (--result_exp <= 0) return 0; }
    andi    a5, a4, 0x80
    bne     a5, x0, Lpack      # 已有 hidden 1 → 結束規格化
    slli    a4, a4, 1          # 左移補位
    addi    t6, t6, -1         # result_exp--
    blt     x0, t6, 14b        # 若 result_exp > 0 繼續規格化，否則回 0
Lret_zero:
    mv      a0, x0             # BF16_ZERO()
    ret

Lpack:
    # ---- 打包回 bf16 ----
    #   return (bf16_t){
    #     .bits = (result_sign << 15) | ((result_exp & 0xFF) << 7) | (result_mant & 0x7F)
    #   };
    slli    a3, a3, 15           # (result_sign << 15)
    andi    a5, t6, 0xFF
    slli    a5, a5, 7            # ((result_exp & 0xFF) << 7)
    andi    a4, a4, 0x7F         # (result_mant & 0x7F)
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
    #   sign_a = (a>>15)&1; sign_b = (b>>15)&1; sign = sign_a ^ sign_b
    #   exp_a  = (a>>7)&0xFF; exp_b = (b>>7)&0xFF
    #   mant_a = a&0x7F;      mant_b = b&0x7F
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

    # IF (exp_a == 0xFF)
    li      a2, 0xFF
    bne     t3, a2, Lmul_chk_b
    #   IF (mant_a != 0) return a; 
    bnez    t5, Lmul_ret_a
    #   ELSE IF (exp_b == 0xFF) {  
    beqz    t4, Lmul_inf_x_zero_chk
    #       return sign ? -Inf : +Inf
    j       Lmul_ret_sign_inf
Lmul_inf_x_zero_chk:
    #       IF (mant_b == 0) return NaN (Inf * 0)
    beqz    t6, Lmul_ret_nan
    #       ELSE return Inf
    j       Lmul_ret_sign_inf

Lmul_chk_b:
    # ELSE IF (exp_b == 0xFF)
    bne     t4, a2, Lmul_check_zero
    #   IF (mant_b != 0) return b;
    bnez    t6, Lmul_ret_b
    #   ELSE IF (exp_a == 0) { if (mant_a==0) return NaN (0*Inf); else return Inf; }
    beqz    t3, Lmul_zero_inf_chk
    j       Lmul_ret_sign_inf
Lmul_zero_inf_chk:
    beqz    t5, Lmul_ret_nan
    j       Lmul_ret_sign_inf

Lmul_check_zero:
    # IF a==0 OR b==0 → return signed zero
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
    # IF (exp_a != 0) mant_a |= 0x80; ELSE 規格化 mant_a
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
    # IF (exp_b != 0) mant_b |= 0x80; ELSE 規格化 mant_b
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
    #   prod = mant_a * mant_b
    mv      a3, zero         # prod
    mv      a5, t6           # mult
    mv      a2, t5           # mcand
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

    #   exp = (exp_a + exp_b + a4) - 127
    add     a2, t3, t4
    add     a2, a2, a4
    addi    a2, a2, -127

    #   IF (prod & 0x8000) { mant = (prod>>8)&0x7F; exp++ } ELSE { mant=(prod>>7)&0x7F; }
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
    # IF (exp >= 0xFF) return signed Inf
    li      t0, 0xFF
    blt     a2, t0, Lmul_under
Lmul_ret_sign_inf:
    slli    a0, t2, 15
    li      t1, 0x7F80
    or      a0, a0, t1
    jr      ra

Lmul_under:
    # IF (exp <= 0)
    blez    a2, Lmul_under_path
    j       Lmul_pack
Lmul_under_path:
    #   若 exp 小很多：直接回 signed 0
    addi    t0, zero, -6     # 門檻（依實作）
    blt     a2, t0, Lmul_ret_sign_zero
    #   否則：右移 mant（產生次正規）
    li      t1, 1
    sub     t1, t1, a2       # shift = 1 - exp
    beqz    t1, Lmul_under_done
Lmul_under_shift:
    srli    a3, a3, 1
    addi    t1, t1, -1
    bnez    t1, Lmul_under_shift
Lmul_under_done:
    mv      a2, zero         # exp=0（次正規）

Lmul_pack:
    # bits = (sign<<15)|((exp&0xFF)<<7)|(mant&0x7F)
    slli    a0, t2, 15
    andi    t0, a2, 0xFF
    slli    t0, t0, 7
    or      a0, a0, t0
    andi    t1, a3, 0x7F
    or      a0, a0, t1
    jr      ra

Lmul_ret_nan:
    # return NaN
    li      a0, 0x7FC0
    jr      ra
Lmul_ret_a:
    # return a（NaN 傳遞）
    mv      a0, a0
    jr      ra
Lmul_ret_b:
    # return b（NaN 傳遞）
    mv      a0, a1
    jr      ra
Lmul_ret_sign_zero:
    # return (sign<<15) | 0
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

    # sign/exp/mant
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
    slli    t6, t6, 15       # signed result = (sign_a ^ sign_b) << 15

    # IF (b 是 Inf/NaN)
    li      a4, 0xFF
    bne     t3, a4, Ldiv_not_b_inf
    #   IF (mant_b != 0) return b;
    bnez    t5, Ldiv_return_b
    #   ELSE { // b 是 ±Inf
    li      a5, 0xFF
    bne     t2, a5, Ldiv_b_inf_zero
    bnez    t4, Ldiv_b_inf_zero
    #       IF (a 是 ±0) return NaN
    li      a0, 0x7FC0
    j       Ldiv_ep
Ldiv_b_inf_zero:
    #       ELSE return signed 0 
    mv      a0, t6
    j       Ldiv_ep

Ldiv_not_b_inf:
    # ELSE IF
    beqz    t3, Ldiv_chk_b_mant
    j       Ldiv_chk_a_inf
Ldiv_chk_b_mant:
    #   IF (mant_b == 0)
    bnez    t5, Ldiv_chk_a_inf
    #       IF (a.exp == 0) { if (a.mant==0) return NaN(0/0); else return ±Inf(非零/0); }
    beqz    t2, Ldiv_both_zero
    j       Ldiv_by_zero_ret_inf
Ldiv_both_zero:
    beqz    t4, Ldiv_return_nan
Ldiv_by_zero_ret_inf:
    li      a0, 0x7F80       # ±Inf
    or      a0, a0, t6
    j       Ldiv_ep

Ldiv_chk_a_inf:
    # IF (a 是 Inf/NaN)
    li      a4, 0xFF
    bne     t2, a4, Ldiv_a_not_inf
    #   IF (mant_a != 0) return a;   // NaN 傳遞
    bnez    t4, Ldiv_return_a
    #   ELSE return signed Inf (Inf / finite)
    li      a0, 0x7F80
    or      a0, a0, t6
    j       Ldiv_ep

Ldiv_a_not_inf:
    # IF (a == 0) return signed 0
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
    # 加隱藏位：IF (exp!=0) mant|=0x80
    beqz    t2, Ldiv_no_imp_a
    ori     t4, t4, 0x80
Ldiv_no_imp_a:
    beqz    t3, Ldiv_no_imp_b
    ori     t5, t5, 0x80
Ldiv_no_imp_b:

    # quotient = (mant_a << 15) / mant_b
    slli    a2, t4, 15       # remainder
    mv      a3, t5           # divisor
    li      a4, 0            # quotient
    li      a5, 0            # i=0
Ldiv_loop_cond:
    li      a7, 16
    bge     a5, a7, Ldiv_loop_end
    slli    a4, a4, 1        # quotient <<= 1
    li      a7, 15
    sub     a7, a7, a5
    sll     a7, a3, a7       # divisor << (15 - i)
    bltu    a2, a7, Ldiv_no_sub
    sub     a2, a2, a7       # remainder -= shifted_divisor
    ori     a4, a4, 1        # quotient bit = 1
Ldiv_no_sub:
    addi    a5, a5, 1
    j       Ldiv_loop_cond
Ldiv_loop_end:

    #   exp = (exp_a - exp_b) + 127 - (exp_a==0 ? 1:0) + (exp_b==0 ? 1:0)
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
    # IF (quot & 0x8000) mant = (quot>>8); ELSE 左移直到 MSB=1 再 >>8
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
    srli    a4, a4, 8          # 取 7-bit mantissa

Ldiv_pack:
    # 溢位/下溢判斷 + 打包
    andi    a4, a4, 0x7F
    li      a7, 0xFF
    blt     a6, a7, Ldiv_under
    # OVERFLOW → ±Inf
    li      a0, 0x7F80
    or      a0, a0, t6
    j       Ldiv_ep
Ldiv_under:
    # IF (exp <= 0) return signed 0
    blez    a6, Ldiv_signed_zero
    # 正常：bits = sign | (exp<<7) | mant
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
    sw s5, 8(sp)

    mv      s0, a0          # s0 = a0 (input)

    # sign = (a>>15)&1, exp = (a>>7)&0xFF, mant = a & 0x7F
    srli    t0, s0, 15
    andi    t0, t0, 1          # t0 = sign
    srli    t1, s0, 7
    andi    t1, t1, 0xFF       # t1 = exp
    andi    t2, s0, 0x7F       # t2 = mant

    #exp==0xFF
    li      t3, 0xFF
    bne     t1, t3, sqrt_not_inf_nan   # exp != 0xFF

    bnez    t2, sqrt_ret_a            # mant != 0 → NaN
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

sqrt_ret_a:
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
    lw s5, 8(sp)
    addi sp, sp, 36
    ret
