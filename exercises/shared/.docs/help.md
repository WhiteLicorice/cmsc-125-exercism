# Help

## Things to check when you're stuck

- Your function receives its inputs in registers `a0`, `a1`, `a2` and so on, in the order they appear in the function declaration at the top of the test file.
- Put your answer in `a0` before you `ret`.
- You can freely change `a0`–`a7` and `t0`–`t6`.
  If you use `s0`–`s11`, or call another function (which changes `ra`), save the old values on the stack first and restore them before you return.
- Strings end with a zero byte.
  Use `lbu` to load one character at a time, and remember to write the zero byte at the end of any string you produce.
- Check the type of each array in the function declaration to see how many bytes each element takes:
  4 bytes for `int32_t` and `uint32_t` (use `lw` and `sw`), 2 bytes for `int16_t` and `uint16_t` (use `lh` or `lhu`, and `sh`), and 1 byte for `uint8_t` (use `lbu` and `sb`).

## Resources

To get help if you're having trouble, you can use one of the following resources:

- The [RISC-V reference card][reference-card] lists the instructions, pseudo-instructions and registers.
- The [RISC-V Assembly Programmer's Manual][asm-manual] explains the assembler's syntax, directives and pseudo-instructions such as `li`, `la` and `mv`.
- The [RISC-V calling convention][psabi] describes which registers hold arguments and return values, and which must be preserved.
- The [RISC-V specifications][isa-manual] describe exactly what every instruction does.
- [Stack Overflow][stack-overflow] can be used to search for your problem and see if it has been answered already.
  You can also ask and answer questions.

[reference-card]: https://github.com/jameslzhu/riscv-card/releases/download/latest/riscv-card.pdf
[asm-manual]: https://github.com/riscv-non-isa/riscv-asm-manual/blob/main/src/asm-manual.adoc
[psabi]: https://github.com/riscv-non-isa/riscv-elf-psabi-doc
[isa-manual]: https://github.com/riscv/riscv-isa-manual/releases
[stack-overflow]: https://stackoverflow.com/questions/tagged/riscv
