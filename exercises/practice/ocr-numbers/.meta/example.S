.equ INVALID_ROWS, -2
.equ INVALID_COLUMNS, -1
.equ SUCCESS, 0

.section .rodata

digit9: .ascii " _ |_| _|   "
digit8: .ascii " _ |_||_|   "
digit7: .ascii " _   |  |   "
digit6: .ascii " _ |_ |_|   "
digit5: .ascii " _ |_  _|   "
digit4: .ascii "   |_|  |   "
digit3: .ascii " _  _| _|   "
digit2: .ascii " _  _||_    "
digit1: .ascii "     |  |   "
digit0: .ascii " _ | ||_|   "

.text
.globl convert

/* extern error_t convert(char *buffer, const char *grid); */
convert:
        addi    sp, sp, -16
        sw      s0, 0(sp)
        sw      s1, 4(sp)
        sw      s2, 8(sp)
        sw      s3, 12(sp)
        lb      t4, 0(a1)
        move    a2, a1
        li      t5, '\n'
        beqz    t4, .success

.scan_line:
        lb      t4, 0(a2)
        addi    a2, a2, 1
        bne     t4, t5, .scan_line

        sub     a2, a2, a1
        li      t5, 3
        addi    t4, a2, -1
        remu    t4, t4, t5
        bnez    t4, .invalid_columns

        move    s0, a1
        move    t0, zero

.count_lines:
        add     s0, s0, a2
        lb      t4, 0(s0)
        addi    t0, t0, 1
        bnez    t4, .count_lines

        andi    t4, t0, 3
        srli    t0, t0, 2
        bnez    t4, .invalid_rows

        move    s0, a1

.block_row:
        li      t1, 1

.cell:
        la      s2, digit9
        li      t3, 10

.digit:
        addi    s3, s2, -3
        sub     s1, s0, a2
        addi    t3, t3, -1
        li      t2, 5

.glyph_row:
        addi    s3, s3, 3
        addi    t2, t2, -1
        add     s1, s1, a2
        beqz    t2, .cell_done

        lb      t4, 0(s1)
        lb      t5, 0(s3)
        bne     t5, t4, .mismatch

        lb      t4, 1(s1)
        lb      t5, 1(s3)
        bne     t5, t4, .mismatch

        lb      t4, 2(s1)
        lb      t5, 2(s3)
        beq     t5, t4, .glyph_row

.mismatch:
        addi    s2, s2, 12
        bnez    t3, .digit

        li      t3, '?' - '0'

.cell_done:
        addi    t3, t3, '0'
        sb      t3, 0(a0)

        addi    t1, t1, 3
        addi    a0, a0, 1
        addi    s0, s0, 3

.cell_test:
        blt     t1, a2, .cell

        li      t4, ','
        addi    t0, t0, -1
        sb      t4, 0(a0)
        addi    a0, a0, 1
        addi    t4, a2, -1
        sub     s0, s0, t4
        slli    t4, a2, 2
        add     s0, s0, t4

.block_row_test:
        bnez    t0, .block_row

        addi    a0, a0, -1

.success:
        sb      zero, 0(a0)
        li      a0, SUCCESS

.return:
        lw      s3, 12(sp)
        lw      s2, 8(sp)
        lw      s1, 4(sp)
        lw      s0, 0(sp)
        addi    sp, sp, 16
        ret

.invalid_rows:
        li      a0, INVALID_ROWS
        j       .return

.invalid_columns:
        li      a0, INVALID_COLUMNS
        j       .return
