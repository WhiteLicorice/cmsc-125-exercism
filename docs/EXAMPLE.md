# Example

```riscvasm
.equ FRAME_SIZE, 16

.text
.global is_triple
```

Lines that start with a dot are _directives_: instructions for the assembler, rather than for the processor.
`.equ` gives the name `FRAME_SIZE` to the number 16.
`.text` says that what follows is code.
`.global` makes the label `is_triple` visible outside this file, so other code can call it.
You may also see `.globl`, which means the same thing.

```riscvasm
/* bool is_triple(unsigned a, unsigned b, unsigned c); */
is_triple:
```

`is_triple` checks whether `a² + b² = c²`, returning 1 if so and 0 otherwise.
For example, `(6, 8, 10)` gives 1, because `36 + 64 = 100`.
The label `is_triple` marks where the function starts.
It is called with `a`, `b` and `c` in the registers `a0`, `a1` and `a2`.

```riscvasm
        addi    sp, sp, -FRAME_SIZE
        sw      ra, 12(sp)      /* save the return address */
        sw      a1, 8(sp)       /* save b */
        sw      a2, 4(sp)       /* save c */
```

The register `ra` holds the _return address_, the place in the caller to go back to when we finish.
Each `call` overwrites `ra`, so we first save it on the _stack_.
The stack grows down, towards smaller addresses, so subtracting 16 from the stack pointer `sp` reserves 16 bytes for us.
(`sp` must always be a multiple of 16.)
We also save `b` and `c`, because a function we call is allowed to change the `a` registers.

```riscvasm
        call    square          /* a0 = a * a */
        sw      a0, 0(sp)       /* save a * a */
```

`a` is already in `a0`, where `square` expects its input.
`call` sets `ra` to the next instruction and jumps to `square`, which returns its result in `a0`.

```riscvasm
        lw      a0, 8(sp)       /* a0 = b */
        call    square          /* a0 = b * b */
        lw      t0, 0(sp)       /* t0 = a * a */
        add     t0, t0, a0      /* t0 = a * a + b * b */
        sw      t0, 0(sp)       /* save a * a + b * b */
```

We load `b` back from the stack, square it, and add it to `a * a`.

```riscvasm
        lw      a0, 4(sp)       /* a0 = c */
        call    square          /* a0 = c * c */
        lw      t0, 0(sp)       /* t0 = a * a + b * b */
        sub     a0, t0, a0      /* a0 = a * a + b * b - c * c */
        seqz    a0, a0          /* a0 = 1 if that is zero, otherwise 0 */
```

The difference is zero exactly when `a² + b² = c²`.
`seqz` ("set if equal to zero") turns that into 1 or 0.

```riscvasm
        lw      ra, 12(sp)      /* restore the return address */
        addi    sp, sp, FRAME_SIZE
        ret
```

We restore `ra` and hand back the 16 bytes of stack.
`ret` then jumps to the address in `ra`, back to the caller.

```riscvasm
/* unsigned square(unsigned n); */
square:
        mul     a0, a0, a0      /* n * n */
        ret
```

`square` calls no other function, so `ra` stays intact and there is nothing to save.
It is not marked `.global`, because only `is_triple` uses it.
