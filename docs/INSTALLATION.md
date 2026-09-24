# Installation

Solutions on this track are written in 32-bit RISC-V assembly and run under emulation, so no RISC-V hardware is needed.
Each exercise ships with a Makefile that builds the tests and runs them.
To use it, you need three tools:

- [Zig][zig], which provides the RISC-V assembler, C compiler and linker through `zig cc`.
- [Make][make], which runs the build.
- `qemu-riscv32` from [QEMU][qemu], which runs the resulting program.

## macOS

Launch a Linux virtual machine using any suitable virtualization solution (e.g., [Lima][lima]) and follow a Linux distribution section below.

## Windows

Use [Windows Subsystem for Linux][wsl] and follow a Linux distribution section below.
Alternatively, set up a Linux virtual machine.

## Debian / Ubuntu

Install Make and QEMU's user-mode emulators:

```shell
sudo apt install make qemu-user
```

Then install Zig 0.15.2 or later as described under [Direct download][zig-install].

## Fedora

Install all three tools with:

```shell
sudo dnf install zig make qemu-user
```

## Arch Linux

Install all three tools with:

```shell
sudo pacman -S zig make qemu-user
```

## openSUSE Tumbleweed

Install all three tools with:

```shell
sudo zypper install zig make qemu-linux-user
```

## Checking your installation

Confirm that all three tools are found:

```shell
zig version
make --version
qemu-riscv32 --version
```

Then download an exercise with the Exercism CLI and run its tests:

```shell
exercism download --track=risc-v --exercise=hello-world
cd ~/exercism/risc-v/hello-world/
make
```

[zig]: https://ziglang.org/
[zig-install]: https://ziglang.org/learn/getting-started/#direct
[make]: https://www.gnu.org/software/make/
[qemu]: https://www.qemu.org/
[wsl]: https://docs.microsoft.com/en-gb/windows/wsl/about
[lima]: https://lima-vm.io/
