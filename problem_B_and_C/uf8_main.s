    .text
    .globl main
    
# ------------------------------------------------------------
# main：依序測試 decode 與 encode
# ------------------------------------------------------------
main:
    # --- 測試 decode(0x52) ---
    li      a0, 0x52
    jal     ra, decode
    li      a7, 1
    ecall
    
    li a0, 10      # '\n' 的 ASCII 碼
    li a7, 11      # print character
    ecall


    # --- 測試 encode(560) ---
    li      a0, 560
    jal     ra, encode
    li      a7, 1
    ecall
    
    li a7, 10    # exit
    ecall


# ------------------------------------------------------------
# decode(a0=uf8): 回傳 uint32 到 a0
# 使用到: t0..t4
# ------------------------------------------------------------
decode:
    andi    t0, a0, 0x0f       # mantissa
    srli    t1, a0, 4          # exponent

    li      t2, 15
    sub     t2, t2, t1         # t2 = 15 - exponent

    li      t3, 0x7FFF
    srl     t3, t3, t2         # 0x7FFF >> (15 - exponent)
    slli    t3, t3, 4          # offset

    sll     t4, t0, t1         # mantissa << exponent
    add     a0, t4, t3         # return
    ret

# ------------------------------------------------------------
# encode(a0=value): 回傳 uf8 到 a0
#  t0..t6
# ------------------------------------------------------------
encode:

    mv      s0, a0             # 保存原始 value 到 s0

    # --- encode ---
    # if (value < 16) return value;
    li      t0, 16
    bltu    s0, t0, encode_ret_short   # 用 s0(原始 value) 來比較

    # --- clz ---
    # 計算 s0 的 leading zeros，結果放回 a0
    mv      a0, s0
    li      t0, 32
    li      t1, 16
1:  srl     t2, a0, t1
    beq     t2, zero, 2f
    sub     t0, t0, t1
    mv      a0, t2
2:  srli    t1, t1, 1
    bnez    t1, 1b
    sub     a0, t0, a0         # a0 = lz(value)
    # -----------------------------------

    mv      t4, a0             # t4 = lz

    # msb = 31 - lz
    li      t5, 31
    sub     t5, t5, t4         # t5 = msb

    # exponent = 0; overflow = 0;
    li      t1, 0              # t1 = exponent
    li      t2, 0              # t2 = overflow

    # if (msb >= 5) { exponent = msb - 4; if (exponent > 15) exponent = 15; ... }
    li      t6, 5
    blt     t5, t6, skip_estimate

    addi    t1, t5, -4         # exponent = msb - 4
    li      t6, 15
    bgtu    t1, t6, clip_to_15
    j       no_clip
clip_to_15:
    li      t1, 15
no_clip:

    # for (e=0; e<exponent; ++e) overflow = (overflow<<1) + 16;
    li      t3, 0              # t3 = e
for_e_loop:
    beq     t3, t1, for_e_done
    slli    t2, t2, 1          # overflow <<= 1
    addi    t2, t2, 16         # overflow += 16
    addi    t3, t3, 1
    j       for_e_loop
for_e_done:

    # while (exponent>0 && value<overflow) {
    #   overflow = (overflow - 16) >> 1; exponent--;
    # }
adj_loop:
    beqz    t1, adj_done
    bltu    s0, t2, adj_step   # s0比較
    j       adj_done
adj_step:
    addi    t2, t2, -16        # overflow -= 16
    srli    t2, t2, 1          # overflow >>= 1
    addi    t1, t1, -1         # exponent--
    j       adj_loop
adj_done:

skip_estimate:
    # while (exponent < 15) {
    #   next_overflow = (overflow<<1) + 16;
    #   if (value < next_overflow) break;
    #   overflow = next_overflow; exponent++;
    # }
while_loop:
    li      t6, 15
    beq     t1, t6, while_done

    slli    t3, t2, 1          # t3 = overflow << 1
    addi    t3, t3, 16         # t3 = next_overflow
    bltu    s0, t3, while_done # 用 s0(原始 value) 比較

    mv      t2, t3             # overflow = next_overflow
    addi    t1, t1, 1          # exponent++
    j       while_loop
while_done:

    # mantissa = (value - overflow) >> exponent;
    sub     t3, s0, t2         # (value - overflow)
    srl     t3, t3, t1         # >> exponent => mantissa

    # return (exponent<<4) | mantissa;
    slli    t4, t1, 4
    or      a0, t4, t3
    j       encode_ret

encode_ret_short:
    # value < 16，直接回傳原始 value
    mv      a0, s0
    ret

encode_ret:
    ret



