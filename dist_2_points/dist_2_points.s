.data
# =========================================
# Common Constants (bf16)
# =========================================
.equ BF16_SIGN_MASK, 0x8000
.equ BF16_EXP_MASK, 0x7F80
.equ BF16_MANT_MASK, 0x007F
.equ BF16_EXP_BIAS, 127
.equ BF16_POS_INF, 0x7F80
.equ BF16_NEG_INF, 0xFF80
.equ BF16_NAN, 0x7FC0
.equ BF16_ZERO, 0x0000
.equ BF16_NEG_ZERO, 0x8000

# =========================================
# Test Data: Nearest Distance Between Two Points
# =========================================
start_msg: .string "===== Nearest Distance Calculation (BF16) ====="
end_msg: .string "===== Complete ====="
input_msg: .string "Test Case "
result_msg: .string "Nearest Distance: "
newline: .string "\n"

pass_msg:          .string "PASS\n"
fail_msg_prefix:   .string "FAIL (exp: "
fail_msg_mid:      .string ", got: "
fail_msg_tail:     .string ")\n"
arrow_msg:         .string " -> "


# Test data format:
# count (number of test cases)
# For each case:
#   Number of points in set A (n_a)
#   Number of points in set B (n_b)
#   All coordinates of A points (x, y) - bf16 format
#   All coordinates of B points (x, y) - bf16 format
#   Expected minimum distance - bf16 format

test_data:
.word 3  # 3 testcases

# Test case 1: A={(0,0), (1,0)}, B={(0,1), (1,1)}
.word 2  # n_a
.word 2  # n_b
# A points
.word 0x0000, 0x0000  # (0, 0)
.word 0x3F80, 0x0000  # (1, 0)
# B points
.word 0x0000, 0x3F80  # (0, 1)
.word 0x3F80, 0x3F80  # (1, 1)
# Expected result: sqrt(1) = 1.0
.word 0x3F80

# testcase 2: A={(0,0)}, B={(3,4)}
.word 1  # n_a
.word 1  # n_b
# A points
.word 0x0000, 0x0000  # (0, 0)
# B points
.word 0x4040, 0x4080  # (3, 4)
# Expected result: sqrt(25) = 5.0
.word 0x40A0

# testcase 3: A={(0,0), (2,0)}, B={(1,1), (3,1)}
.word 2  # n_a
.word 2  # n_b
# A points
.word 0x0000, 0x0000  # (0, 0)
.word 0x4000, 0x0000  # (2, 0)
# B points
.word 0x3F80, 0x3F80  # (1, 1)
.word 0x4040, 0x3F80  # (3, 1)
# Expected result: sqrt(2) ≈ 1.414
.word 0x3FB5

.text
.globl main

# ==========================================
# main
# ==========================================
main:
    # Start Message
    la a0, start_msg
    li a7, 4
    ecall
    li a0, 10
    li a7, 11
    ecall

    la s0, test_data
    lw s1, 0(s0)      # s1 = testcase數量
    addi s0, s0, 4
    li s2, 0          # s2 = 當前案例索引

main_test_loop:
    bge s2, s1, main_done
    
    # Print testcase number
    la a0, input_msg
    li a7, 4
    ecall
    addi a0, s2, 1
    li a7, 1
    ecall
    li a0, 10
    li a7, 11
    ecall
    
    # Read testcase data
    lw a0, 0(s0)      # n_a
    lw a1, 4(s0)      # n_b
    addi a2, s0, 8    # A 點陣列起始位址
    
    # Calculate starting address of B points array
    slli t0, a0, 3    # n_a * 8 (每點 2 個 word)
    add a3, a2, t0    # B 點陣列起始位址
    
    # Save data pointers
    addi sp, sp, -16
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw ra, 12(sp)
    
    # Call nearest distance calculation
    jal ra, find_min_distance
    mv s3, a0         # s3 = 計算結果
    
    # Restore data pointers
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    
    # Calculate expected result address
    lw t0, 0(s0)      # n_a
    lw t1, 4(s0)      # n_b
    add t2, t0, t1    # total points
    slli t2, t2, 3    # * 8 bytes (每點2個word=8 bytes)
    addi t2, t2, 8    # + 2 words header = 8 bytes  (修正：原本多加了4)
    add t3, s0, t2
    lw s4, 0(t3)      # s4 = 預期結果 (bf16位元)

    # Print result line: Nearest Distance: <value> -> (PASS/FAIL ...)
    la a0, result_msg
    li a7, 4
    ecall

    mv a0, s3         # got
    li a7, 1
    ecall

    la a0, arrow_msg  # " -> "
    li a7, 4
    ecall

    beq s3, s4, __print_pass

    # FAIL branch: "FAIL (exp: <exp>, got: <got>)\n"
    la a0, fail_msg_prefix
    li a7, 4
    ecall

    mv a0, s4         # exp
    li a7, 1
    ecall

    la a0, fail_msg_mid
    li a7, 4
    ecall

    mv a0, s3         # got
    li a7, 1
    ecall

    la a0, fail_msg_tail
    li a7, 4
    ecall
    j __after_passfail

__print_pass:
    la a0, pass_msg
    li a7, 4
    ecall

__after_passfail:
    # Move to the next testcase (skip expected result 1 word)
    addi s0, t3, 4
    addi s2, s2, 1
    j main_test_loop


main_done:
    # End Message
    la a0, end_msg
    li a7, 4
    ecall
    li a0, 10
    li a7, 11
    ecall
    
    li a0, 0
    li a7, 10
    ecall

# ==========================================
# find_min_distance
# Input: a0 = n_a, a1 = n_b, a2 = A array, a3 = B array
# Output: a0 = Minimum distance (bf16)
# ==========================================
find_min_distance:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4, 8(sp)
    sw s5, 4(sp)
    
    mv s0, a0         # s0 = n_a
    mv s1, a1         # s1 = n_b
    mv s2, a2         # s2 = A陣列
    mv s3, a3         # s3 = B陣列
    li s4, 0x7F80     # s4 = min_dist (初始為 +Inf)
    li s5, 0          # s5 = i (A的索引)

find_outer_loop:
    bge s5, s0, find_done
    
    # Get coordinates of A[i]
    slli t0, s5, 3
    add t0, s2, t0
    lw a0, 0(t0)      # ax
    lw a1, 4(t0)      # ay
    
    li t1, 0          # t1 = j (B的索引)

find_inner_loop:
    bge t1, s1, find_next_i
    
    # Get coordinates of B[j]
    slli t2, t1, 3
    add t2, s3, t2
    lw a2, 0(t2)      # bx
    lw a3, 4(t2)      # by
    
    # Save loop variables
    addi sp, sp, -12
    sw a0, 0(sp)
    sw a1, 4(sp)
    sw t1, 8(sp)
    
    # Calculate distance
    jal ra, calc_distance
    mv t3, a0         # t3 = dist
    
    # Restore loop variables
    lw a0, 0(sp)
    lw a1, 4(sp)
    lw t1, 8(sp)
    addi sp, sp, 12
    
    # Update minimum distance (simple bit comparison)
    bltu t3, s4, find_update_min
    j find_continue

find_update_min:
    mv s4, t3

find_continue:
    addi t1, t1, 1
    j find_inner_loop

find_next_i:
    addi s5, s5, 1
    j find_outer_loop

find_done:
    mv a0, s4
    
    lw ra, 28(sp)
    lw s0, 24(sp)
    lw s1, 20(sp)
    lw s2, 16(sp)
    lw s3, 12(sp)
    lw s4, 8(sp)
    lw s5, 4(sp)
    addi sp, sp, 32
    ret

# ==========================================
# calc_distance
# Calculate sqrt((bx-ax)^2 + (by-ay)^2)
# Input: a0=ax, a1=ay, a2=bx, a3=by (bf16)
# Output: a0 = Distance (bf16)
# ==========================================
calc_distance:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)

    mv s3, a0    # save ax
    mv s1, a1    # save ay
    mv s2, a3    # save by

    # dx = bx - ax
    mv a0, a2    # a0 = bx
    mv a1, s3    # a1 = ax
    jal ra, bf16_sub   # a0 = dx
    mv a1, a0
    jal ra, bf16_mul   # a0 = dx^2
    mv s0, a0          # s0 = dx^2

    # dy = by - ay
    mv a0, s2    # a0 = by
    mv a1, s1    # a1 = ay
    jal ra, bf16_sub   # a0 = dy
    mv a1, a0
    jal ra, bf16_mul   # a0 = dy^2

    # dx^2 + dy^2
    mv a1, a0    # a1 = dy^2
    mv a0, s0    # a0 = dx^2
    jal ra, bf16_add   # a0 = sum

    # sqrt(sum)
    jal ra, bf16_sqrt  # a0 = distance

    lw ra, 20(sp)
    lw s0, 16(sp)
    lw s1, 12(sp)
    lw s2, 8(sp)
    lw s3, 4(sp)
    addi sp, sp, 24
    ret


# ==========================================
# BF16 Operations
# ==========================================

bf16_isnan:
    li t2, 0x7F80
    and t0, a0, t2
    bne t0, t2, Lnan_false
    li t3, 0x007F
    and t1, a0, t3
    beq t1, x0, Lnan_false
    li a0, 1
    ret
Lnan_false:
    mv a0, x0
    ret

bf16_isinf:
    li t2, 0x7F80
    and t0, a0, t2
    bne t0, t2, Linf_false
    li t3, 0x007F
    and t1, a0, t3
    bne t1, x0, Linf_false
    li a0, 1
    ret
Linf_false:
    mv a0, x0
    ret

bf16_iszero:
    li t0, 0x7FFF
    and t0, a0, t0
    bne t0, x0, Lzero_false
    li a0, 1
    ret
Lzero_false:
    mv a0, x0
    ret

f32_to_bf16:
    srli t0, a0, 23
    andi t0, t0, 0x0FF
    li t1, 0x0FF
    beq t0, t1, Lfte_special
    srli t2, a0, 16
    andi t2, t2, 1
    li t3, 0x7FFF
    add t2, t2, t3
    add a0, a0, t2
    srli a0, a0, 16
    ret
Lfte_special:
    srli a0, a0, 16
    li t0, 0xFFFF
    and a0, a0, t0
    ret

bf16_to_f32:
    li t0, 0xFFFF
    and a0, a0, t0
    slli a0, a0, 16
    ret

bf16_add:
    srli t0, a0, 15
    andi t0, t0, 1
    srli t1, a1, 15
    andi t1, t1, 1
    srli t2, a0, 7
    andi t2, t2, 0xFF
    srli t3, a1, 7
    andi t3, t3, 0xFF
    andi t4, a0, 0x7F
    andi t5, a1, 0x7F
    li t6, 0xFF
    bne t2, t6, add_1f
    beq t4, x0, La_is_inf
    mv a0, a0
    ret
La_is_inf:
    bne t3, t6, Lret_a
    beq t5, x0, add_0f
    mv a0, a1
    ret
add_0f:
    bne t0, t1, Lret_NaN
    mv a0, a1
    ret
Lret_NaN:
    li a0, BF16_NAN
    ret
Lret_a:
    mv a0, a0
    ret
add_1f:
    bne t3, t6, add_2f
    mv a0, a1
    ret
add_2f:
    beq t2, x0, add_3f
    j add_4f
add_3f:
    beq t4, x0, Lret_b
    j add_4f
Lret_b:
    mv a0, a1
    ret
add_4f:
    beq t3, x0, add_5f
    j add_6f
add_5f:
    beq t5, x0, Lret_a2
    j add_6f
Lret_a2:
    mv a0, a0
    ret
add_6f:
    beq t2, x0, add_7f
    ori t4, t4, 0x80
add_7f:
    beq t3, x0, add_8f
    ori t5, t5, 0x80
add_8f:
    sub a2, t2, t3
    beq a2, x0, add_9f
    blt x0, a2, add_10f
    neg a3, a2
    li t6, 8
    blt t6, a3, Lret_b
    srl t4, t4, a3
    mv t6, t3
    j add_11f
add_10f:
    li t6, 8
    blt t6, a2, Lret_a2
    srl t5, t5, a2
    mv t6, t2
    j add_11f
add_9f:
    mv t6, t2
add_11f:
    bne t0, t1, Ldiff_sign
    add a4, t4, t5
    mv a3, t0
    andi a5, a4, 0x100
    beq a5, x0, Lpack
    srli a4, a4, 1
    addi t6, t6, 1
    li a5, 0xFF
    blt t6, a5, Lpack
    slli a3, a3, 15
    li a5, 0x7F80
    or a0, a3, a5
    ret
Ldiff_sign:
    bge t4, t5, add_12f
    sub a4, t5, t4
    mv a3, t1
    j add_13f
add_12f:
    sub a4, t4, t5
    mv a3, t0
add_13f:
    beq a4, x0, Lret_zero
add_14f:
    andi a5, a4, 0x80
    bne a5, x0, Lpack
    slli a4, a4, 1
    addi t6, t6, -1
    blt x0, t6, add_14f
Lret_zero:
    mv a0, x0
    ret
Lpack:
    slli a3, a3, 15
    andi t0, a2, 0xFF
    slli t0, t0, 7
    andi t4, a4, 0x7F
    or a3, a3, t0
    or a0, a3, t4
    ret

bf16_sub:
    li t0, 0x8000
    xor a1, a1, t0
    j bf16_add

bf16_mul:
    srli t0, a0, 15
    andi t0, t0, 1
    srli t1, a1, 15
    andi t1, t1, 1
    srli t3, a0, 7
    andi t3, t3, 0xFF
    srli t4, a1, 7
    andi t4, t4, 0xFF
    andi t5, a0, 0x7F
    andi t6, a1, 0x7F
    xor t2, t0, t1
    li a2, 0xFF
    bne t3, a2, Lmul_chk_b
    bnez t5, Lmul_ret_a
    beqz t4, Lmul_inf_x_zero_chk
    j Lmul_ret_sign_inf
Lmul_inf_x_zero_chk:
    beqz t6, Lmul_ret_nan
    j Lmul_ret_sign_inf
Lmul_chk_b:
    bne t4, a2, Lmul_check_zero
    bnez t6, Lmul_ret_b
    beqz t3, Lmul_zero_inf_chk
    j Lmul_ret_sign_inf
Lmul_zero_inf_chk:
    beqz t5, Lmul_ret_nan
    j Lmul_ret_sign_inf
Lmul_check_zero:
    beqz t3, Lmul_a_mant0
    j Lmul_b_zero
Lmul_a_mant0:
    beqz t5, Lmul_ret_sign_zero
Lmul_b_zero:
    beqz t4, Lmul_b_mant0
    j Lmul_norm_in
Lmul_b_mant0:
    beqz t6, Lmul_ret_sign_zero
Lmul_norm_in:
    li a4, 0
    beqz t3, Lmul_norm_a_sub
    ori t5, t5, 0x80
    j Lmul_norm_b_chk
Lmul_norm_a_sub:
Lmul_norm_a_loop:
    andi a5, t5, 0x80
    bnez a5, Lmul_norm_a_done
    slli t5, t5, 1
    addi a4, a4, -1
    j Lmul_norm_a_loop
Lmul_norm_a_done:
    li t3, 1
Lmul_norm_b_chk:
    beqz t4, Lmul_norm_b_sub
    ori t6, t6, 0x80
    j Lmul_do
Lmul_norm_b_sub:
Lmul_norm_b_loop:
    andi a5, t6, 0x80
    bnez a5, Lmul_norm_b_done
    slli t6, t6, 1
    addi a4, a4, -1
    j Lmul_norm_b_loop
Lmul_norm_b_done:
    li t4, 1
Lmul_do:
    mv a3, zero
    mv a5, t6
    mv a2, t5
    li t0, 8
Lmul_loop:
    andi t1, a5, 1
    beqz t1, Lmul_skip_add
    add a3, a3, a2
Lmul_skip_add:
    slli a2, a2, 1
    srli a5, a5, 1
    addi t0, t0, -1
    bnez t0, Lmul_loop
    add a2, t3, t4
    add a2, a2, a4
    addi a2, a2, -127
    li t0, 0x8000
    and t1, a3, t0
    beqz t1, Lmul_norm_else
    srli a3, a3, 8
    andi a3, a3, 0x7F
    addi a2, a2, 1
    j Lmul_after_norm
Lmul_norm_else:
    srli a3, a3, 7
    andi a3, a3, 0x7F
Lmul_after_norm:
    li t0, 0xFF
    blt a2, t0, Lmul_under
Lmul_ret_sign_inf:
    slli a0, t2, 15
    li t1, 0x7F80
    or a0, a0, t1
    jr ra
Lmul_under:
    blez a2, Lmul_under_path
    j Lmul_pack
Lmul_under_path:
    addi t0, zero, -6
    blt a2, t0, Lmul_ret_sign_zero
    li t1, 1
    sub t1, t1, a2
    beqz t1, Lmul_under_done
Lmul_under_shift:
    srli a3, a3, 1
    addi t1, t1, -1
    bnez t1, Lmul_under_shift
Lmul_under_done:
    mv a2, zero
Lmul_pack:
    slli a0, t2, 15
    andi t0, a2, 0xFF
    slli t0, t0, 7
    or a0, a0, t0
    andi t1, a3, 0x7F
    or a0, a0, t1
    jr ra
Lmul_ret_nan:
    li a0, 0x7FC0
    jr ra
Lmul_ret_a:
    mv a0, a0
    jr ra
Lmul_ret_b:
    mv a0, a1
    jr ra
Lmul_ret_sign_zero:
    slli a0, t2, 15
    jr ra

bf16_div:
    addi sp, sp, -16
    sw ra, 12(sp)
    srli t0, a0, 15
    andi t0, t0, 1
    srli t1, a1, 15
    andi t1, t1, 1
    srli t2, a0, 7
    andi t2, t2, 0xFF
    srli t3, a1, 7
    andi t3, t3, 0xFF
    andi t4, a0, 0x007F
    andi t5, a1, 0x007F
    xor t6, t0, t1
    slli t6, t6, 15
    li a4, 0xFF
    bne t3, a4, Ldiv_not_b_inf
    bnez t5, Ldiv_return_b
    li a5, 0xFF
    bne t2, a5, Ldiv_b_inf_zero
    bnez t4, Ldiv_b_inf_zero
    li a0, 0x7FC0
    j Ldiv_ep
Ldiv_b_inf_zero:
    mv a0, t6
    j Ldiv_ep
Ldiv_not_b_inf:
    beqz t3, Ldiv_chk_b_mant
    j Ldiv_chk_a_inf
Ldiv_chk_b_mant:
    bnez t5, Ldiv_chk_a_inf
    beqz t2, Ldiv_both_zero
    j Ldiv_by_zero_ret_inf
Ldiv_both_zero:
    beqz t4, Ldiv_return_nan
Ldiv_by_zero_ret_inf:
    li a0, 0x7F80
    or a0, a0, t6
    j Ldiv_ep
Ldiv_chk_a_inf:
    li a4, 0xFF
    bne t2, a4, Ldiv_a_not_inf
    bnez t4, Ldiv_return_a
    li a0, 0x7F80
    or a0, a0, t6
    j Ldiv_ep
Ldiv_a_not_inf:
    beqz t2, Ldiv_a_zero_path
    j Ldiv_normals
Ldiv_a_zero_path:
    bnez t4, Ldiv_normals
    mv a0, t6
    j Ldiv_ep
Ldiv_return_a:
    mv a0, a0
    j Ldiv_ep
Ldiv_return_b:
    mv a0, a1
    j Ldiv_ep
Ldiv_return_nan:
    li a0, 0x7FC0
    j Ldiv_ep
Ldiv_normals:
    beqz t2, Ldiv_no_imp_a
    ori t4, t4, 0x80
Ldiv_no_imp_a:
    beqz t3, Ldiv_no_imp_b
    ori t5, t5, 0x80
Ldiv_no_imp_b:
    slli a2, t4, 15
    mv a3, t5
    li a4, 0
    li a5, 0
Ldiv_loop_cond:
    li a7, 16
    bge a5, a7, Ldiv_loop_end
    slli a4, a4, 1
    li a7, 15
    sub a7, a7, a5
    sll a7, a3, a7
    bltu a2, a7, Ldiv_no_sub
    sub a2, a2, a7
    ori a4, a4, 1
Ldiv_no_sub:
    addi a5, a5, 1
    j Ldiv_loop_cond
Ldiv_loop_end:
    sub a6, t2, t3
    li a7, 127
    add a6, a6, a7
    beqz t2, Ldiv_adj_a_sub
    j Ldiv_adj_b_add
Ldiv_adj_a_sub:
    addi a6, a6, -1
Ldiv_adj_b_add:
    beqz t3, Ldiv_adj_b_do
    j Ldiv_norm_start
Ldiv_adj_b_do:
    addi a6, a6, 1
Ldiv_norm_start:
    li a7, 0x8000
    and a7, a4, a7
    beqz a7, Ldiv_shift_up
    srli a4, a4, 8
    j Ldiv_pack
Ldiv_shift_up:
Ldiv_norm_while:
    li a7, 0x8000
    and a7, a4, a7
    bnez a7, Ldiv_done_up
    li t6, 1
    ble a6, t6, Ldiv_done_up
    slli a4, a4, 1
    addi a6, a6, -1
    j Ldiv_norm_while
Ldiv_done_up:
    srli a4, a4, 8
Ldiv_pack:
    andi a4, a4, 0x7F
    li a7, 0xFF
    blt a6, a7, Ldiv_under
    li a0, 0x7F80
    or a0, a0, t6
    j Ldiv_ep
Ldiv_under:
    blez a6, Ldiv_signed_zero
    andi a6, a6, 0xFF
    slli a6, a6, 7
    or a0, t6, a6
    or a0, a0, a4
    j Ldiv_ep
Ldiv_signed_zero:
    mv a0, t6
Ldiv_ep:
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

bf16_sqrt:
    addi sp, sp, -36
    sw ra, 32(sp)
    sw s0, 28(sp)
    sw s1, 24(sp)
    sw s2, 20(sp)
    sw s3, 16(sp)
    sw s4, 12(sp)
    sw s5, 8(sp)
    mv s0, a0
    srli t0, s0, 15
    andi t0, t0, 1
    srli t1, s0, 7
    andi t1, t1, 0xFF
    andi t2, s0, 0x7F
    li t3, 0xFF
    bne t1, t3, sqrt_not_inf_nan
    bnez t2, sqrt_ret_a
    bnez t0, sqrt_ret_nan
    j sqrt_ret_a
sqrt_not_inf_nan:
    bnez t1, sqrt_not_zero_case
    bnez t2, sqrt_not_zero_case
    li a0, BF16_ZERO
    j bf16_sqrt_end
sqrt_not_zero_case:
    beqz t0, sqrt_not_negative
    li a0, BF16_NAN
    j bf16_sqrt_end
sqrt_not_negative:
    bnez t1, sqrt_denorm_checked
    li a0, BF16_ZERO
    j bf16_sqrt_end
sqrt_denorm_checked:
    li t3, BF16_EXP_BIAS
    sub s1, t1, t3
    li s2, 0x80
    or s2, s2, t2
    andi t4, s1, 1
    beqz t4, sqrt_even_exp
    slli s2, s2, 1
    addi t5, s1, -1
    srai t5, t5, 1
    addi s3, t5, BF16_EXP_BIAS
    j after_new_exp
sqrt_even_exp:
    srai t5, s1, 1
    addi s3, t5, BF16_EXP_BIAS
after_new_exp:
    li s4, 90
    li t6, 256
    li t5, 128
sqrt_bsearch_loop:
    bgt s4, t6, sqrt_bsearch_done
    add t0, s4, t6
    srai t0, t0, 1
    mv a2, t0
    mv a3, t0
    li t2, 0
    li s5, 16
sqrt_imul_loop:
    andi a4, a3, 1
    beqz a4, sqrt_imul_skip
    add t2, t2, a2
sqrt_imul_skip:
    slli a2, a2, 1
    srli a3, a3, 1
    addi s5, s5, -1
    bnez s5, sqrt_imul_loop
    mv t1, t2
    srli t1, t1, 7
    bgt t1, s2, sq_gt_m
    mv t5, t0
    addi s4, t0, 1
    j sqrt_bsearch_loop
sq_gt_m:
    addi t6, t0, -1
    j sqrt_bsearch_loop
sqrt_bsearch_done:
    li t0, 256
    blt t5, t0, chk_under_128
    srli t5, t5, 1
    addi s3, s3, 1
    j sqrt_norm_done
chk_under_128:
    li t0, 128
    bge t5, t0, sqrt_norm_done
sqrt_norm_loop:
    blt t5, t0, sqrt_need_shift
    j sqrt_norm_done
sqrt_need_shift:
    li t1, 1
    ble s3, t1, sqrt_norm_done
    slli t5, t5, 1
    addi s3, s3, -1
    j sqrt_norm_loop
sqrt_norm_done:
    andi t0, t5, 0x7F
    li t1, 0xFF
    blt s3, t1, sqrt_chk_underflow
    li a0, BF16_POS_INF
    j bf16_sqrt_end
sqrt_chk_underflow:
    blez s3, sqrt_ret_zero
    slli t1, s3, 7
    or a0, t1, t0
    j bf16_sqrt_end
sqrt_ret_zero:
    li a0, BF16_ZERO
    j bf16_sqrt_end
sqrt_ret_a:
    mv a0, s0
    j bf16_sqrt_end
sqrt_ret_nan:
    li a0, 0x7FC0
    j bf16_sqrt_end
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