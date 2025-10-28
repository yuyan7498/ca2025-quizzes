    .text
    .align 2
    .globl clz32
    .type clz32, @function
clz32:
    li      t0, 32                # n = 32
    li      t1, 16                # c = 16
1:
    srl     t2, a0, t1            # y = x >> c
    beq     t2, x0, 2f            # if (!y) skip update
    sub     t0, t0, t1            # n -= c
    mv      a0, t2                # x = y
2:
    srli    t1, t1, 1             # c >>= 1
    bnez    t1, 1b                # while (c)
    sub     a0, t0, a0            # return n - x
    ret

.size clz32, .-clz32

    .align 2
    .globl decode
    .type decode, @function
decode:
    andi    t0, a0, 0x0f       # mantissa m
    srli    t1, a0, 4          # exponent e

    li      t2, 15
    sub     t2, t2, t1         # t2 = 15 - e

    li      t3, 0x7FFF
    srl     t3, t3, t2         # 0x7FFF >> (15 - e)
    slli    t3, t3, 4          # offset

    sll     t4, t0, t1         # m << e
    add     a0, t4, t3         # return value
    ret

.size decode, .-decode

    .align 2
    .globl encode
    .type encode, @function
encode:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)

    mv      s0, a0             # value to s0

    li      t0, 16
    bltu    s0, t0, EncodeRetShort

    mv      a0, s0
    jal     ra, clz32          # a0 = leading zeros
    mv      t4, a0

    li      t5, 31
    sub     t5, t5, t4         # msb = 31 - lz

    li      t1, 0              # exponent
    li      t2, 0              # overflow

    li      t6, 5
    blt     t5, t6, SkipEstimate

    addi    t1, t5, -4         # exponent = msb - 4
    li      t6, 15
    bgtu    t1, t6, ClipTo15
    j       NoClip
ClipTo15:
    li      t1, 15
NoClip:

    li      t3, 0
ForELoop:
    beq     t3, t1, ForEDone
    slli    t2, t2, 1
    addi    t2, t2, 16
    addi    t3, t3, 1
    j       ForELoop
ForEDone:

AdjLoop:
    beqz    t1, AdjDone
    bltu    s0, t2, AdjStep
    j       AdjDone
AdjStep:
    addi    t2, t2, -16
    srli    t2, t2, 1
    addi    t1, t1, -1
    j       AdjLoop
AdjDone:

SkipEstimate:
    li      t6, 15
    beq     t1, t6, WhileDone

    slli    t3, t2, 1
    addi    t3, t3, 16
    bltu    s0, t3, WhileDone

    mv      t2, t3
    addi    t1, t1, 1
    j       SkipEstimate

WhileDone:
    sub     t3, s0, t2
    srl     t3, t3, t1

    slli    t4, t1, 4
    or      a0, t4, t3
    j       EncodeRet

EncodeRetShort:
    mv      a0, s0

EncodeRet:
    lw      ra, 12(sp)
    lw      s0, 8(sp)
    addi    sp, sp, 16
    ret

.size encode, .-encode
