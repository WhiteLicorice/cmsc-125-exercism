# About

Every program you have ever run, whether a game, a web browser or a phone app, ends up as a long list of tiny instructions that the processor carries out one at a time.
Assembly language is how you write those instructions yourself.
Instead of variables, lists and `for` loops, you work with the processor's own building blocks: a small set of registers, memory addresses, and jumps from one instruction to another.

RISC-V (pronounced "risk five") is a design for processors that started at the University of California, Berkeley in 2010.
Unlike most processor designs, it is an open standard: nobody has to pay or ask permission to build a RISC-V chip, and the specification is free for anyone to read.
RISC-V chips are found in microcontrollers, single-board computers, storage devices and more.

RISC-V is a good first assembly language because it was designed to be simple.
Its instructions follow a small number of regular patterns, and its 32 registers have clear, consistent roles, so there is far less to memorise than with the processors in most laptops.
That simplicity is also why many universities now use RISC-V to teach how computers work.

Here is a small taste, a function that adds two numbers:

```riscv
add_numbers:
        add     a0, a0, a1      /* a0 = a0 + a1 */
        ret                     /* return to the caller, with the answer in a0 */
```

On this track you write 32-bit RISC-V assembly.
You do not need any RISC-V hardware: your programs are tested on an emulator, which pretends to be a RISC-V processor.
You can solve exercises in the online editor, or on your own computer using free tools.

Learning assembly takes patience, but it pays off.
Once you have seen what a loop or a function call looks like to the processor, every other programming language makes a little more sense.
