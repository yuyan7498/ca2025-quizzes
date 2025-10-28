    .text
    .align 2

    .equ BF16_SIGN_MASK, 0x8000
    .equ BF16_EXP_MASK,  0x7F80
    .equ BF16_MANT_MASK, 0x007F
    .equ BF16_EXP_BIAS,  127

    .globl bf16_isnan_asm
    .type bf16_isnan_asm, @function
bf16_isnan_asm:
    li      t2, BF16_EXP_MASK
    and     t0, a0, t2
    bne     t0, t2, .Lnan_false
    li      t3, BF16_MANT_MASK
    and     t1, a0, t3
    beq     t1, x0, .Lnan_false
    li      a0, 1
    ret
.Lnan_false:
    mv      a0, x0
    ret

    .globl bf16_isinf_asm
    .type bf16_isinf_asm, @function
bf16_isinf_asm:
    li      t2, BF16_EXP_MASK
    and     t0, a0, t2
    bne     t0, t2, .Linf_false
    li      t3, BF16_MANT_MASK
    and     t1, a0, t3
    bne     t1, x0, .Linf_false
    li      a0, 1
    ret
.Linf_false:
    mv      a0, x0
    ret

    .globl bf16_iszero_asm
    .type bf16_iszero_asm, @function
bf16_iszero_asm:
    li      t0, 0x7FFF
    and     t0, a0, t0
    bne     t0, x0, .Lzero_false
    li      a0, 1
    ret
.Lzero_false:
    mv      a0, x0
    ret

    .globl f32_to_bf16_asm
    .type f32_to_bf16_asm, @function
f32_to_bf16_asm:
    srli    t0, a0, 23
    andi    t0, t0, 0x0FF
    li      t1, 0x0FF
    beq     t0, t1, .Lf32_special

    srli    t2, a0, 16
    andi    t2, t2, 1
    li      t3, 0x7FFF
    add     t2, t2, t3
    add     a0, a0, t2

    srli    a0, a0, 16
    ret
.Lf32_special:
    srli    a0, a0, 16
    li      t0, 0xFFFF
    and     a0, a0, t0
    ret

    .globl bf16_to_f32_asm
    .type bf16_to_f32_asm, @function
bf16_to_f32_asm:
    li      t0, 0xFFFF
    and     a0, a0, t0
    slli    a0, a0, 16
    ret

    .globl bf16_add_asm
    .type bf16_add_asm, @function
bf16_add_asm:
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
    bne     t2, t6, .Ladd_check_b_inf
    beq     t4, x0, .Ladd_a_inf
    ret
.Ladd_a_inf:
    bne     t3, t6, .Ladd_return_a
    beq     t5, x0, .Ladd_b_inf_same
    mv      a0, a1
    ret
.Ladd_b_inf_same:
    bne     t0, t1, .Ladd_return_nan
    mv      a0, a1
    ret
.Ladd_return_nan:
    li      a0, 0x7FC0
    ret
.Ladd_return_a:
    ret

.Ladd_check_b_inf:
    bne     t3, t6, .Ladd_check_zero_a
    mv      a0, a1
    ret

.Ladd_check_zero_a:
    beq     t2, x0, .Ladd_zero_a_mant
    j       .Ladd_check_zero_b
.Ladd_zero_a_mant:
    beq     t4, x0, .Ladd_return_b
    j       .Ladd_check_zero_b
.Ladd_return_b:
    mv      a0, a1
    ret

.Ladd_check_zero_b:
    beq     t3, x0, .Ladd_zero_b_mant
    j       .Ladd_add_hidden
.Ladd_zero_b_mant:
    beq     t5, x0, .Ladd_return_a2
    j       .Ladd_add_hidden
.Ladd_return_a2:
    ret

.Ladd_add_hidden:
    beq     t2, x0, .Ladd_no_hidden_a
    ori     t4, t4, 0x80
.Ladd_no_hidden_a:
    beq     t3, x0, .Ladd_no_hidden_b
    ori     t5, t5, 0x80
.Ladd_no_hidden_b:

    sub     a2, t2, t3
    beq     a2, x0, .Ladd_exp_equal
    blt     x0, a2, .Ladd_exp_gt

    neg     a3, a2
    li      t6, 8
    blt     t6, a3, .Ladd_return_b
    srl     t4, t4, a3
    mv      t6, t3
    j       .Ladd_align_done
.Ladd_exp_gt:
    li      t6, 8
    blt     t6, a2, .Ladd_return_a2
    srl     t5, t5, a2
    mv      t6, t2
    j       .Ladd_align_done
.Ladd_exp_equal:
    mv      t6, t2

.Ladd_align_done:
    bne     t0, t1, .Ladd_diff_sign

    add     a4, t4, t5
    mv      a3, t0
    andi    a5, a4, 0x100
    beq     a5, x0, .Ladd_pack
    srli    a4, a4, 1
    addi    t6, t6, 1
    li      a5, 0xFF
    blt     t6, a5, .Ladd_pack
    slli    a3, a3, 15
    li      a5, 0x7F80
    or      a0, a3, a5
    ret

.Ladd_diff_sign:
    bge     t4, t5, .Ladd_mant_a_ge
    sub     a4, t5, t4
    mv      a3, t1
    j       .Ladd_diff_norm
.Ladd_mant_a_ge:
    sub     a4, t4, t5
    mv      a3, t0
.Ladd_diff_norm:
    beq     a4, x0, .Ladd_return_zero
.Ladd_norm_loop:
    andi    a5, a4, 0x80
    bne     a5, x0, .Ladd_pack
    slli    a4, a4, 1
    addi    t6, t6, -1
    blt     x0, t6, .Ladd_norm_loop
.Ladd_return_zero:
    mv      a0, x0
    ret

.Ladd_pack:
    slli    a3, a3, 15
    andi    a5, t6, 0xFF
    slli    a5, a5, 7
    andi    a4, a4, 0x7F
    or      a3, a3, a5
    or      a0, a3, a4
    ret

    .globl bf16_sub_asm
    .type bf16_sub_asm, @function
bf16_sub_asm:
    li      t0, 0x8000
    xor     a1, a1, t0
    j       bf16_add_asm

    .globl bf16_mul_asm
    .type bf16_mul_asm, @function
bf16_mul_asm:
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
    bne     t3, a2, .Lmul_check_b
    bnez    t5, .Lmul_ret_a
    bnez    t4, .Lmul_signed_inf
    beqz    t6, .Lmul_ret_nan
    j       .Lmul_signed_inf

.Lmul_check_b:
    bne     t4, a2, .Lmul_zero_path
    bnez    t6, .Lmul_ret_b
    beqz    t3, .Lmul_zero_inf_chk
    j       .Lmul_signed_inf
.Lmul_zero_inf_chk:
    beqz    t5, .Lmul_ret_nan
    j       .Lmul_signed_inf

.Lmul_zero_path:
    beqz    t3, .Lmul_a_zero_mant
    j       .Lmul_check_b_zero
.Lmul_a_zero_mant:
    beqz    t5, .Lmul_signed_zero
.Lmul_check_b_zero:
    beqz    t4, .Lmul_b_zero_mant
    j       .Lmul_prepare
.Lmul_b_zero_mant:
    beqz    t6, .Lmul_signed_zero

.Lmul_prepare:
    li      a4, 0
    beqz    t3, .Lmul_norm_a
    ori     t5, t5, 0x80
    j       .Lmul_norm_b
.Lmul_norm_a:
.Lmul_norm_a_loop:
    andi    a5, t5, 0x80
    bnez    a5, .Lmul_norm_a_done
    slli    t5, t5, 1
    addi    a4, a4, -1
    j       .Lmul_norm_a_loop
.Lmul_norm_a_done:
    li      t3, 1

.Lmul_norm_b:
    beqz    t4, .Lmul_norm_b_loop
    ori     t6, t6, 0x80
    j       .Lmul_mul
.Lmul_norm_b_loop:
    andi    a5, t6, 0x80
    bnez    a5, .Lmul_norm_b_done
    slli    t6, t6, 1
    addi    a4, a4, -1
    j       .Lmul_norm_b_loop
.Lmul_norm_b_done:
    li      t4, 1

.Lmul_mul:
    mv      a3, x0
    mv      a5, t6
    mv      a2, t5
    li      t0, 8
.Lmul_loop:
    andi    t1, a5, 1
    beqz    t1, .Lmul_skip_add
    add     a3, a3, a2
.Lmul_skip_add:
    slli    a2, a2, 1
    srli    a5, a5, 1
    addi    t0, t0, -1
    bnez    t0, .Lmul_loop

    add     a2, t3, t4
    add     a2, a2, a4
    addi    a2, a2, -127

    li      t0, 0x8000
    and     t1, a3, t0
    beqz    t1, .Lmul_shift
    srli    a3, a3, 8
    andi    a3, a3, 0x7F
    addi    a2, a2, 1
    j       .Lmul_after_norm
.Lmul_shift:
    srli    a3, a3, 7
    andi    a3, a3, 0x7F
.Lmul_after_norm:
    li      t0, 0xFF
    blt     a2, t0, .Lmul_underflow
.Lmul_signed_inf:
    slli    a0, t2, 15
    li      t1, 0x7F80
    or      a0, a0, t1
    ret

.Lmul_underflow:
    blez    a2, .Lmul_under_path
    j       .Lmul_pack
.Lmul_under_path:
    addi    t0, x0, -6
    blt     a2, t0, .Lmul_signed_zero
    li      t1, 1
    sub     t1, t1, a2
    beqz    t1, .Lmul_under_done
.Lmul_under_shift:
    srli    a3, a3, 1
    addi    t1, t1, -1
    bnez    t1, .Lmul_under_shift
.Lmul_under_done:
    mv      a2, x0

.Lmul_pack:
    slli    a0, t2, 15
    andi    t0, a2, 0xFF
    slli    t0, t0, 7
    or      a0, a0, t0
    andi    t1, a3, 0x7F
    or      a0, a0, t1
    ret

.Lmul_ret_nan:
    li      a0, 0x7FC0
    ret
.Lmul_ret_a:
    ret
.Lmul_ret_b:
    mv      a0, a1
    ret
.Lmul_signed_zero:
    slli    a0, t2, 15
    ret

    .globl bf16_div_asm
    .type bf16_div_asm, @function
bf16_div_asm:
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
    bne     t3, a4, .Ldiv_not_b_inf
    bnez    t5, .Ldiv_return_b
    li      a5, 0xFF
    bne     t2, a5, .Ldiv_b_inf_zero
    bnez    t4, .Ldiv_b_inf_zero
    li      a0, 0x7FC0
    j       .Ldiv_epilogue
.Ldiv_b_inf_zero:
    mv      a0, t6
    j       .Ldiv_epilogue

.Ldiv_not_b_inf:
    beqz    t3, .Ldiv_check_b_zero
    j       .Ldiv_check_a_inf
.Ldiv_check_b_zero:
    bnez    t5, .Ldiv_check_a_inf
    beqz    t2, .Ldiv_both_zero
    j       .Ldiv_div_zero_ret_inf
.Ldiv_both_zero:
    beqz    t4, .Ldiv_return_nan
.Ldiv_div_zero_ret_inf:
    li      a0, 0x7F80
    or      a0, a0, t6
    j       .Ldiv_epilogue

.Ldiv_check_a_inf:
    li      a4, 0xFF
    bne     t2, a4, .Ldiv_a_not_inf
    bnez    t4, .Ldiv_return_a
    li      a0, 0x7F80
    or      a0, a0, t6
    j       .Ldiv_epilogue

.Ldiv_a_not_inf:
    beqz    t2, .Ldiv_a_zero_path
    j       .Ldiv_normals
.Ldiv_a_zero_path:
    bnez    t4, .Ldiv_normals
    mv      a0, t6
    j       .Ldiv_epilogue

.Ldiv_return_a:
    j       .Ldiv_epilogue_restore
.Ldiv_return_b:
    mv      a0, a1
    j       .Ldiv_epilogue_restore
.Ldiv_return_nan:
    li      a0, 0x7FC0
    j       .Ldiv_epilogue

.Ldiv_normals:
    beqz    t2, .Ldiv_no_hidden_a
    ori     t4, t4, 0x80
.Ldiv_no_hidden_a:
    beqz    t3, .Ldiv_no_hidden_b
    ori     t5, t5, 0x80
.Ldiv_no_hidden_b:

    slli    a2, t4, 15
    mv      a3, t5
    li      a4, 0
    li      a5, 0
.Ldiv_loop_cond:
    li      a7, 16
    bge     a5, a7, .Ldiv_loop_end
    slli    a4, a4, 1
    li      a7, 15
    sub     a7, a7, a5
    sll     a7, a3, a7
    bltu    a2, a7, .Ldiv_no_sub
    sub     a2, a2, a7
    ori     a4, a4, 1
.Ldiv_no_sub:
    addi    a5, a5, 1
    j       .Ldiv_loop_cond
.Ldiv_loop_end:

    sub     a6, t2, t3
    li      a7, 127
    add     a6, a6, a7
    beqz    t2, .Ldiv_adj_a
    j       .Ldiv_adj_b
.Ldiv_adj_a:
    addi    a6, a6, -1
.Ldiv_adj_b:
    beqz    t3, .Ldiv_adj_b_do
    j       .Ldiv_norm_start
.Ldiv_adj_b_do:
    addi    a6, a6, 1

.Ldiv_norm_start:
    li      a7, 0x8000
    and     a7, a4, a7
    beqz    a7, .Ldiv_shift_up
    srli    a4, a4, 8
    j       .Ldiv_pack

.Ldiv_shift_up:
.Ldiv_norm_while:
    li      a7, 0x8000
    and     a7, a4, a7
    bnez    a7, .Ldiv_norm_done
    li      t6, 1
    ble     a6, t6, .Ldiv_norm_done
    slli    a4, a4, 1
    addi    a6, a6, -1
    j       .Ldiv_norm_while
.Ldiv_norm_done:
    srli    a4, a4, 8

.Ldiv_pack:
    andi    a4, a4, 0x7F
    li      a7, 0xFF
    blt     a6, a7, .Ldiv_under
    li      a0, 0x7F80
    or      a0, a0, t6
    j       .Ldiv_epilogue
.Ldiv_under:
    blez    a6, .Ldiv_signed_zero
    andi    a6, a6, 0xFF
    slli    a6, a6, 7
    or      a0, t6, a6
    or      a0, a0, a4
    j       .Ldiv_epilogue
.Ldiv_signed_zero:
    mv      a0, t6

.Ldiv_epilogue:
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret
.Ldiv_epilogue_restore:
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

