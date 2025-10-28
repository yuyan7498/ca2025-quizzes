main:
    
    li      a0, 0x00F00000

    # --- clz  ---
    li      t0, 32
    li      t1, 16
1:  srl     t2, a0, t1
    beq     t2, zero, 2f
    sub     t0, t0, t1
    mv      a0, t2
2:  srli    t1, t1, 1
    bnez    t1, 1b
    sub     a0, t0, a0
    # -----------------------------------

    li a7 1
    ecall

