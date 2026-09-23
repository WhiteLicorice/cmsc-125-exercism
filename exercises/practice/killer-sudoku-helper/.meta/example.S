.text
.globl combinations


search:
        beqz    a2, .search_zero

        beqz    a1, .search_ret

        beqz    a5, .search_ret

        addi    sp, sp, -16
        sw      ra, 0(sp)

        addi    a5, a5, -1

        call    search

        sll     t3, t4, a5              /* 1 << digit */
        ble     a1, a5, .search_exit

        and     t2, a3, t3
        bnez    t2, .search_exit

        sub     a1, a1, a5
        addi    a1, a1, -1
        addi    a2, a2, -1
        add     a4, a4, t3

        call    search

        sll     t3, t4, a5              /* 1 << digit */
        sub     a4, a4, t3
        addi    a2, a2, 1
        addi    a1, a1, 1
        add     a1, a1, a5

.search_exit:
        addi    a5, a5, 1
        lw      ra, 0(sp)
        addi    sp, sp, 16
        jr      ra

.search_zero:
        bnez    a1, .search_ret

        sw      a4, 0(a0)
        addi    a0, a0, 4

.search_ret:
        jr      ra


/* extern size_t combinations(uint32_t* dest, uint32_t sum, uint32_t size, uint32_t exclude); */
combinations:
        move    t6, ra
        move    t5, a0                  /* dest */
        li      t4, 1
        move    a4, zero                /* bitset */
        li      a5, 9                   /* digit */
        call    search
        sub     a0, a0, t5
        srli    a0, a0, 2
        jr      t6
