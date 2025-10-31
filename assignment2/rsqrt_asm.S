    .text
    .align 2

    .extern clz32
    .extern rsqrt_table
    .extern rsqrt_mul32
    .extern rsqrt_mul32_u64

    .globl fast_rsqrt_asm
    .type fast_rsqrt_asm, @function
fast_rsqrt_asm:
    beq     a0, x0, .Lret_zero

    addi    sp, sp, -32
    sw      ra, 28(sp)
    sw      s0, 24(sp)
    sw      s1, 20(sp)
    sw      s2, 16(sp)
    sw      s3, 12(sp)
    sw      s4, 8(sp)
    sw      s5, 4(sp)

    mv      s0, a0              # s0 = x
    mv      a0, s0
    call    clz32
    li      t0, 31
    sub     s1, t0, a0          # s1 = exp

    li      t0, 1
    sll     s2, t0, s1          # s2 = base

    la      t0, rsqrt_table
    slli    t1, s1, 2
    add     t0, t0, t1
    lw      s3, 0(t0)           # s3 = y
    li      t2, 31
    beq     s1, t2, .Lnext_zero
    lw      t3, 4(t0)
    j       .Lhave_next
.Lnext_zero:
    li      t3, 0
.Lhave_next:
    sub     s4, s3, t3          # s4 = delta

    sub     t4, s0, s2
    slli    t4, t4, 16
    srl     t4, t4, s1
    mv      s5, t4              # s5 = frac

    mv      a0, s4
    mv      a1, s5
    call    rsqrt_mul32
    mv      t0, a0              # low
    mv      t1, a1              # high
    slli    t2, t1, 16
    srli    t3, t0, 16
    or      t6, t2, t3          # interp
    sub     s3, s3, t6

    li      s5, 2
.Lnewton_loop:
    beqz    s5, .Lloop_done

    mv      a0, s3
    mv      a1, s3
    call    rsqrt_mul32
    mv      t0, a0              # y_sq low
    mv      t1, a1              # y_sq high

    mv      a0, s0
    mv      a1, t0
    mv      a2, t1
    call    rsqrt_mul32_u64
    mv      t2, a0              # prod low
    mv      t3, a1              # prod high

    li      t6, 3
    bltu    t6, t3, .Lterm_zero
    bltu    t3, t6, .Lterm_less
    beqz    t2, .Lterm_zero
    j       .Lterm_zero

.Lterm_less:
    li      t4, 3
    sub     t4, t4, t3          # term high preliminary
    li      t5, 0
    sub     t5, t5, t2          # term low = -prod_low
    sltu    t6, x0, t2          # borrow
    sub     t4, t4, t6
    j       .Lterm_ready

.Lterm_zero:
    li      t4, 0
    li      t5, 0

.Lterm_ready:
    mv      a0, s3
    mv      a1, t5
    mv      a2, t4
    call    rsqrt_mul32_u64
    mv      t0, a0
    mv      t1, a1
    srli    s3, t1, 1
    bnez    s3, .Lafter_y_check
    li      s3, 1
.Lafter_y_check:
    addi    s5, s5, -1
    j       .Lnewton_loop

.Lloop_done:
    mv      a0, s3
    lw      s5, 4(sp)
    lw      s4, 8(sp)
    lw      s3, 12(sp)
    lw      s2, 16(sp)
    lw      s1, 20(sp)
    lw      s0, 24(sp)
    lw      ra, 28(sp)
    addi    sp, sp, 32
    ret

.Lret_zero:
    ret

.size fast_rsqrt_asm, .-fast_rsqrt_asm
