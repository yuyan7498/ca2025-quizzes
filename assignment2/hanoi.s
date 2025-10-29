    .text
    .align 2
    .globl hanoi_run
    .type hanoi_run, @function
hanoi_run:
    addi    sp, sp, -96
    sw      ra, 92(sp)
    sw      s0, 88(sp)
    sw      s1, 84(sp)
    sw      s2, 80(sp)
    sw      s3, 76(sp)
    sw      s4, 72(sp)
    sw      s5, 68(sp)
    sw      s6, 64(sp)

    li      t0, 0x15
    sw      t0, 20(sp)
    sw      t0, 24(sp)
    sw      t0, 28(sp)

    sw      zero, 20(sp)
    sw      zero, 24(sp)
    sw      zero, 28(sp)

    li      s0, 1              # move counter

.hanoi_loop:
    li      t0, 8
    beq     s0, t0, .hanoi_finish

    srli    t1, s0, 1          # n >> 1
    xor     t2, s0, t1         # gray(n)

    addi    t3, s0, -1
    srli    t4, t3, 1
    xor     t3, t3, t4         # gray(n-1)

    xor     t5, t2, t3         # changed bits

    li      s1, 0
    andi    t6, t5, 1
    bne     t6, x0, .disk_identified

    li      s1, 1
    andi    t6, t5, 2
    bne     t6, x0, .disk_identified

    li      s1, 2

.disk_identified:
    andi    t6, t5, 5
    li      t0, 5
    beq     t6, t0, .continue_move

.continue_move:
    slli    t0, s1, 2
    addi    t0, t0, 20
    add     t0, sp, t0
    lw      s2, 0(t0)          # current position

    bne     s1, x0, .handle_large

    addi    s3, s2, 2
    li      t1, 3
    blt     s3, t1, .display_move
    sub     s3, s3, t1
    j       .display_move

.handle_large:
    lw      t1, 20(sp)         # small disk position
    li      s3, 3
    sub     s3, s3, s2
    sub     s3, s3, t1

.display_move:
    la      s4, hanoi_obdata
    add     t0, s4, s2
    lbu     a0, 0(t0)
    li      t1, 0x6F
    xor     a0, a0, t1
    addi    a0, a0, -0x12
    mv      s5, a0             # from peg char

    add     t0, s4, s3
    lbu     a0, 0(t0)
    xor     a0, a0, t1
    addi    a0, a0, -0x12
    mv      s6, a0             # to peg char

    la      a0, hanoi_str1
    jal     ra, print_cstr

    addi    a0, s1, 1
    jal     ra, print_small_uint

    la      a0, hanoi_str2
    jal     ra, print_cstr

    mv      a0, s5
    jal     ra, print_char

    la      a0, hanoi_str3
    jal     ra, print_cstr

    mv      a0, s6
    jal     ra, print_char

    li      a0, 10
    jal     ra, print_char

    slli    t0, s1, 2
    addi    t0, t0, 20
    add     t0, sp, t0
    sw      s3, 0(t0)

    addi    s0, s0, 1
    j       .hanoi_loop

.hanoi_finish:
    lw      s6, 64(sp)
    lw      s5, 68(sp)
    lw      s4, 72(sp)
    lw      s3, 76(sp)
    lw      s2, 80(sp)
    lw      s1, 84(sp)
    lw      s0, 88(sp)
    lw      ra, 92(sp)
    addi    sp, sp, 96
    ret

.size hanoi_run, .-hanoi_run

# Helper functions ---------------------------------------------------------

    .align 2
    .globl print_cstr
    .type print_cstr, @function
print_cstr:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      a0, 8(sp)

    mv      t0, a0
    li      t1, 0
.len_loop:
    lbu     t2, 0(t0)
    beqz    t2, .len_done
    addi    t0, t0, 1
    addi    t1, t1, 1
    j       .len_loop

.len_done:
    beqz    t1, .print_cstr_done
    li      a0, 1              # STDOUT
    lw      a1, 8(sp)          # pointer
    mv      a2, t1             # length
    li      a7, 64
    ecall

.print_cstr_done:
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

.size print_cstr, .-print_cstr

    .align 2
    .globl print_char
    .type print_char, @function
print_char:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sb      a0, 8(sp)
    li      a0, 1
    addi    a1, sp, 8
    li      a2, 1
    li      a7, 64
    ecall
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

.size print_char, .-print_char

    .align 2
    .globl print_small_uint
    .type print_small_uint, @function
print_small_uint:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    addi    a0, a0, 48
    sb      a0, 8(sp)
    li      a0, 1
    addi    a1, sp, 8
    li      a2, 1
    li      a7, 64
    ecall
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret

.size print_small_uint, .-print_small_uint

    .data
    .align 2
hanoi_obdata:
    .byte   0x3c, 0x3b, 0x3a
hanoi_str1:
    .asciz  "Move Disk "
hanoi_str2:
    .asciz  " from "
hanoi_str3:
    .asciz  " to "
