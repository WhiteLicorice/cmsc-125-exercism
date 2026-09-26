# Resources

## Reference

- The [RISC-V reference card][reference-card] lists the instructions, pseudo-instructions and registers.
- The [RISC-V calling convention][psabi] describes which registers hold function inputs and results, and which a function must preserve.
- The [RISC-V specifications][isa-manual] describe exactly what every instruction does.
- The [GNU assembler manual][gas-directives] describes directives such as `.section`, `.string`, `.word` and `.global`.

## Tools

- [Compiler Explorer][godbolt] shows the assembly a compiler produces for a piece of C code.
  The link opens it with a 32-bit RISC-V compiler, so you can compare your own solutions with what a compiler would write.

## Community

- [RISC-V International][riscv-org] is the organization that looks after the RISC-V standard.
- [r/RISCV][reddit] is a Reddit community that shares news about RISC-V chips, boards and software.
- [Stack Overflow][stack-overflow] has questions and answers about RISC-V assembly.

[reference-card]: https://github.com/jameslzhu/riscv-card/releases/download/latest/riscv-card.pdf
[psabi]: https://github.com/riscv-non-isa/riscv-elf-psabi-doc
[isa-manual]: https://github.com/riscv/riscv-isa-manual/releases
[gas-directives]: https://sourceware.org/binutils/docs/as/Pseudo-Ops.html
[godbolt]: https://godbolt.org/clientstate/eyJzZXNzaW9ucyI6W3siaWQiOjEsImxhbmd1YWdlIjoiYyIsInNvdXJjZSI6ImludCBzcXVhcmUoaW50IG4pIHtcbiAgICByZXR1cm4gbiAqIG47XG59XG4iLCJjb21waWxlcnMiOlt7ImlkIjoicnYzMi1jZ2NjdHJ1bmsiLCJvcHRpb25zIjoiLU8yIn1dfV19
[riscv-org]: https://riscv.org/
[reddit]: https://www.reddit.com/r/RISCV/
[stack-overflow]: https://stackoverflow.com/questions/tagged/riscv
