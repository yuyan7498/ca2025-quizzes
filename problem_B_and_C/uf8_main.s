    .text
    .globl main
    .globl decode
    .globl encode
    .globl clz32

# ------------------------------------------------------------
# UF8 main
# A: decode (UF8→u32)  B: encode (u32→UF8)  C: clz32
#
# ------------------------------------------------------------
main:
    # ---- A ----
    la      a0, sA_head
    li      a7, 4
    ecall

    la      t0, dec_in
    la      t1, dec_exp
    lw      s3, 0(t0)              # s3 = N
    lw      t6, 0(t1)
    addi    s1, t0, 4              # s1 = ptr to inputs
    addi    s2, t1, 4              # s2 = ptr to expected
    li      s4, 0                  # i = 0

DecLoop:
    beq     s4, s3, DecDone

    lw      a0, 0(s1)              # uf8 input
    mv      s5, a0                 # save input for printing
    jal     ra, decode
    mv      t3, a0                 # got
    lw      t2, 0(s2)              # exp

    # print input/exp/got
    la      a0, sInput
    li      a7, 4
    ecall
    mv      a0, s5
    li      a7, 1
    ecall

    la      a0, sExp
    li      a7, 4
    ecall
    mv      a0, t2
    li      a7, 1
    ecall

    la      a0, sGot
    li      a7, 4
    ecall
    mv      a0, t3
    li      a7, 1
    ecall

    li      a0, 10                 # '\n'
    li      a7, 11
    ecall

    # compare and print Pass/FAIL
    bne     t3, t2, DecFail
    la      a0, sPass
    li      a7, 4
    ecall
    j       DecNext
DecFail:
    la      a0, sFail
    li      a7, 4
    ecall

DecNext:
    addi    s1, s1, 4
    addi    s2, s2, 4
    addi    s4, s4, 1
    j       DecLoop

DecDone:

    # ---- B ----
    la      a0, sB_head
    li      a7, 4
    ecall

    la      t0, enc_in
    la      t1, enc_exp
    lw      s3, 0(t0)
    lw      t6, 0(t1)
    addi    s1, t0, 4
    addi    s2, t1, 4
    li      s4, 0

EncLoop:
    beq     s4, s3, EncDone

    lw      a0, 0(s1)              # value input
    mv      s5, a0
    jal     ra, encode
    mv      t3, a0                 # got (uf8 code)
    lw      t2, 0(s2)              # exp

    # print input/exp/got
    la      a0, sInput
    li      a7, 4
    ecall
    mv      a0, s5
    li      a7, 1
    ecall

    la      a0, sExp
    li      a7, 4
    ecall
    mv      a0, t2
    li      a7, 1
    ecall

    la      a0, sGot
    li      a7, 4
    ecall
    mv      a0, t3
    li      a7, 1
    ecall

    li      a0, 10
    li      a7, 11
    ecall

    bne     t3, t2, EncFail
    la      a0, sPass
    li      a7, 4
    ecall
    j       EncNext
EncFail:
    la      a0, sFail
    li      a7, 4
    ecall

EncNext:
    addi    s1, s1, 4
    addi    s2, s2, 4
    addi    s4, s4, 1
    j       EncLoop

EncDone:

    # ---- C ----
    la      a0, sC_head
    li      a7, 4
    ecall

    la      t0, clz_in
    la      t1, clz_exp
    lw      s3, 0(t0)              # N
    lw      t6, 0(t1)
    addi    s1, t0, 4              # ptr in
    addi    s2, t1, 4              # ptr exp
    li      s4, 0

ClzLoop:
    beq     s4, s3, AllDone

    lw      a0, 0(s1)              # input
    mv      s5, a0
    jal     ra, clz32
    mv      t3, a0                 # got
    lw      t2, 0(s2)              # exp

    la      a0, sInput
    li      a7, 4
    ecall
    mv      a0, s5
    li      a7, 1
    ecall

    la      a0, sExp
    li      a7, 4
    ecall
    mv      a0, t2
    li      a7, 1
    ecall

    la      a0, sGot
    li      a7, 4
    ecall
    mv      a0, t3
    li      a7, 1
    ecall

    li      a0, 10
    li      a7, 11
    ecall

    bne     t3, t2, ClzFail
    la      a0, sPass
    li      a7, 4
    ecall
    j       ClzNext
ClzFail:
    la      a0, sFail
    li      a7, 4
    ecall

ClzNext:
    addi    s1, s1, 4
    addi    s2, s2, 4
    addi    s4, s4, 1
    j       ClzLoop

AllDone:
    li      a7, 10
    ecall

# ------------------------------------------------------------
# clz32
# a0=x; returns clz(x). Uses t0=n, t1=c, t2=y
# ------------------------------------------------------------
clz32:
    li      t0, 32                # n = 32
    li      t1, 16                # c = 16
1:
    srl     t2, a0, t1            # y = x >> c
    beq     t2, x0, 2f            # if (!y) skip update
    sub     t0, t0, t1            #   n -= c
    mv      a0, t2                #   x = y
2:
    srli    t1, t1, 1             # c >>= 1
    bnez    t1, 1b                # while (c)
    sub     a0, t0, a0            # return n - x
    ret

# ------------------------------------------------------------
# decode(a0=uf8): return uint32 to a0
# uf8: hi 4bits = exponent (e), lo 4bits = mantissa (m)
# value = ( (0x7FFF >> (15-e)) << 4 ) + (m << e)
# ------------------------------------------------------------
decode:
    andi    t0, a0, 0x0f       # mantissa m
    srli    t1, a0, 4          # exponent e

    li      t2, 15
    sub     t2, t2, t1         # t2 = 15 - e

    li      t3, 0x7FFF
    srl     t3, t3, t2         # 0x7FFF >> (15 - e)
    slli    t3, t3, 4          # offset

    sll     t4, t0, t1         # m << e
    add     a0, t4, t3         # return
    ret

# ------------------------------------------------------------
# encode(a0=value): return uf8 to a0
# use: t0..t6, s0
# value < 16 → return value (e=0, m=value)
# ------------------------------------------------------------
encode:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)

    mv      s0, a0             # value to s0

    # if (value < 16) return value;
    li      t0, 16
    bltu    s0, t0, EncodeRetShort

    # --- lz(value) ---
    mv      a0, s0
    jal     ra, clz32          # a0 = lz
    mv      t4, a0             # t4 = lz

    # msb = 31 - lz
    li      t5, 31
    sub     t5, t5, t4         # t5 = msb

    # exponent = 0; overflow = 0;
    li      t1, 0              # t1 = exponent e
    li      t2, 0              # t2 = overflow

    # if (msb >= 5) { exponent = msb - 4; if (exponent > 15) exponent = 15; ... }
    li      t6, 5
    blt     t5, t6, SkipEstimate

    addi    t1, t5, -4         # exponent = msb - 4
    li      t6, 15
    bgtu    t1, t6, ClipTo15
    j       NoClip
ClipTo15:
    li      t1, 15
NoClip:

    # for (e=0; e<exponent; ++e) overflow = (overflow<<1) + 16;
    li      t3, 0              # t3 = e
ForELoop:
    beq     t3, t1, ForEDone
    slli    t2, t2, 1          # overflow <<= 1
    addi    t2, t2, 16         # overflow += 16
    addi    t3, t3, 1
    j       ForELoop
ForEDone:

    # while (exponent>0 && value<overflow) {
    #   overflow = (overflow - 16) >> 1; exponent--;
    # }
AdjLoop:
    beqz    t1, AdjDone
    bltu    s0, t2, AdjStep
    j       AdjDone
AdjStep:
    addi    t2, t2, -16        # overflow -= 16
    srli    t2, t2, 1          # overflow >>= 1
    addi    t1, t1, -1         # exponent--
    j       AdjLoop
AdjDone:

SkipEstimate:
    # while (exponent < 15) {
    #   next_overflow = (overflow<<1) + 16;
    #   if (value < next_overflow) break;
    #   overflow = next_overflow; exponent++;
    # }
WhileLoop:
    li      t6, 15
    beq     t1, t6, WhileDone

    slli    t3, t2, 1          # t3 = overflow << 1
    addi    t3, t3, 16         # t3 = next_overflow
    bltu    s0, t3, WhileDone

    mv      t2, t3             # overflow = next_overflow
    addi    t1, t1, 1          # exponent++
    j       WhileLoop
WhileDone:

    # mantissa = (value - overflow) >> exponent;
    sub     t3, s0, t2         # (value - overflow)
    srl     t3, t3, t1         # >> exponent => mantissa

    # return (exponent<<4) | mantissa;
    slli    t4, t1, 4
    or      a0, t4, t3
    j       EncodeRet

EncodeRetShort:
    # value < 16 return original value
    mv      a0, s0

EncodeRet:
    lw      ra, 12(sp)
    lw      s0, 8(sp)
    addi    sp, sp, 16
    ret

# ------------------------------
# data
# ------------------------------
    .data
sA_head: .string "\n--- Section A: decode ---\n"
sB_head: .string "\n--- Section B: encode ---\n"
sC_head: .string "\n--- Section C: clz32  ---\n"
sInput:  .string "input: "
sExp:    .string " exp: "
sGot:    .string " got: "
sPass:   .string "Pass\n"
sFail:   .string "FAIL\n"

# A: decode test（uf8 → uint32）
dec_in:
    .word 12
    .word 0      # (0x00)
    .word 15     # (0x0F)
    .word 16     # (0x10)
    .word 31     # (0x1F)
    .word 32     # (0x20)
    .word 36     # (0x24)
    .word 47     # (0x2F)
    .word 48     # (0x30)
    .word 58     # (0x3A)
    .word 79     # (0x4F)
    .word 80     # (0x50)
    .word 82     # (0x52)

dec_exp:
    .word 12
    .word 0
    .word 15
    .word 16
    .word 46
    .word 48
    .word 64
    .word 108
    .word 112
    .word 192
    .word 480
    .word 496
    .word 560

# B: encode test（uint32 → uf8）
enc_in:
    .word 13
    .word 0
    .word 15
    .word 16
    .word 46
    .word 48
    .word 64
    .word 108
    .word 112
    .word 192
    .word 240
    .word 480
    .word 496
    .word 560

enc_exp:
    .word 13
    .word 0      # 0x00
    .word 15     # 0x0F
    .word 16     # 0x10
    .word 31     # 0x1F
    .word 32     # 0x20
    .word 36     # 0x24
    .word 47     # 0x2F
    .word 48     # 0x30
    .word 58     # 0x3A
    .word 64     # 0x40
    .word 79     # 0x4F
    .word 80     # 0x50
    .word 82     # 0x52

# C: clz32 test
clz_in:
    .word 3
    .word 0x00F00000   # clz = 8
    .word 0x00000001   # clz = 31
    .word 0x7FFFFFFF   # clz = 1

clz_exp:
    .word 3
    .word 8
    .word 31
    .word 1
