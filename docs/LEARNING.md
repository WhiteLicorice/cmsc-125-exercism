# Learning

## New to assembly?

Each exercise comes with tests, and your job is to write code that makes them pass.
The tests are written in C, so you will need to read a little C: enough to follow a function declaration and a test that checks its result.
If you have written programs before, you already know the ideas behind loops, `if` statements and functions.
In assembly you build those same ideas yourself, one small instruction at a time.

Start with the easiest exercises and read each test file carefully.
The function declaration near the top tells you what inputs your code receives and what it must return, and each test shows an example input and the answer it expects.
The help that comes with each exercise lists the rules for which registers hold inputs and results.

## Watch instructions run

A good way to learn what an instruction does is to try it and watch what happens.
These free simulators let you type a few RISC-V instructions, run them one at a time, and see how each register and memory location changes:

- [Venus][venus] runs in your web browser, with nothing to install.
- [RARS][rars] is a desktop app that runs on Windows, macOS and Linux.
- [Ripes][ripes] is a desktop app that also shows a diagram of the processor, so you can see how each instruction moves through it.

## Books and courses

- [RISC-V Assembly Programming][riscv-programming] is a free online textbook written for students new to assembly, with exercises and an in-browser simulator.
- [CS61C][cs61c], the computer architecture course at the University of California, Berkeley, teaches RISC-V and publishes its lecture slides and projects online.
- [_Computer Organization and Design RISC-V Edition_][cod-riscv] by David Patterson and John Hennessy is a widely used textbook on how processors work.

## Quick references

- The [Project F RISC-V cheat sheet][cheat-sheet] groups the instructions by what they do, and includes common pseudo-instructions such as `li`, `mv` and `j`.
- The [RISC-V Assembly Programmer's Manual][asm-manual] explains the assembler's syntax and directives such as `.text`, `.global` and `.string`.

[venus]: https://venus.cs61c.org/
[rars]: https://github.com/TheThirdOne/rars
[ripes]: https://github.com/mortbopet/Ripes
[riscv-programming]: https://riscv-programming.org/
[cs61c]: https://cs61c.org/
[cod-riscv]: https://shop.elsevier.com/books/computer-organization-and-design-risc-v-edition/patterson/978-0-12-820331-6
[cheat-sheet]: https://projectf.io/posts/riscv-cheat-sheet/
[asm-manual]: https://github.com/riscv-non-isa/riscv-asm-manual/blob/main/src/asm-manual.adoc
