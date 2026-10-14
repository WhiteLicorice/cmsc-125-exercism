# CMSC 125 Exercise Fork

This repository holds the CMSC 125 RISC-V exercises.
Each student forks this repository one time.
The repository comes from the Exercism RISC-V track.
The fork keeps the full upstream practice catalog of 77 exercises with the exact difficulty value that upstream assigns to each exercise.
Read [UPSTREAM.md](UPSTREAM.md) for the original text and the attribution.

## Your identity

Fill in this table before you submit your work.

| Field | Value |
|:--|:--|
| Full name | <your full name> |
| Student number | <your student number> |
| GitHub account | <your GitHub username> |

## What you do

1. Pick exercises until the total reaches 100 points.
2. Write each solution in the solution file of the exercise.
3. Claim each finished exercise in `completed.txt`.
4. Explain each solution in `EXPLANATIONS.md`.
5. Push your work.
6. Submit the repository URL, the full commit hash, and the CI evidence from that commit.

## Points

| Difficulty | Classification | Points |
|--:|:--|--:|
| 1 to 3 | easy | 10 |
| 4 to 7 | medium | 15 |
| 8 to 10 | hard | 20 |

The exercise marks are 0.3 times the points.
The marks are uncapped.
Ten easy exercises reach 100 points.
`CATALOG.md` lists every exercise, its difficulty, its classification, and its points.

## Run one exercise

Run the public test suite of one exercise:

```shell
make test EXERCISE=hello-world
```

The command builds the solution and the test with Zig.
It runs the test program with `qemu-riscv32` and prints the test result.
An unknown slug stops with an error.

## Score your claims

Run the scorer:

```shell
make test-lab0
```

The scorer reads `completed.txt`.
It runs each claimed exercise with a 60 second limit.
It prints the number of passed, failed, and skipped tests of each exercise.
It prints the earned points and the marks.
An exercise earns its points only when every test runs and passes.
A skipped test, a compile failure, a crash, and a timeout each make the exercise incomplete.

The scorer reads the points and the test names before any solution runs.
It runs each claim in a private copy of the exercise.
It hashes the scoring inputs before the claims run.
The inputs are `catalog.tsv`, the root `Makefile`, `bin/`, and the exercise files other than the student solutions.
It hashes those inputs again after each claim.
A change stops the scorer.
The scorer prints `reason=tamper` with the changed path.
It then prints 0 points and 0 marks, and exits non-zero.
The instructor review compares the other protected files with the course tag.
Those files include `config.json` and `.github/`.
A solution can still find and write a path outside its copy with enough effort.
The instructor review aid flags a system call for that reason.

## Claim an exercise

Put one slug on each line of `completed.txt`.
The file ignores a blank line and a line that starts with `#`.

```text
hello-world
leap
```

Write one entry for each claim in `EXPLANATIONS.md`.
The instructor grades the explanations by review.
CI prints a warning when an entry is missing. The points stay.

## Files that you may change

Change only these files:

- `README.md`, the identity table
- `completed.txt`
- `EXPLANATIONS.md`
- the solution file of an exercise, `exercises/practice/<slug>/<snake_slug>.S`

Every other file is protected.
The tests, `vendor/`, every `Makefile`, `.meta/`, `config.json`, the catalog,
`bin/`, and `.github/` are protected.
The instructor compares your fork with the course tag `v1.0`.

Each exercise has an example solution in `.meta/example.S`.
The exercise `Makefile` does not compile this file.
The example is public. Do not copy it.

## The toolchain

The exercises use Zig, C, and Unity.
The test program runs with `qemu-riscv32`.
`qemu-riscv32` is QEMU user mode. It runs Linux binaries.
It exists only on a Linux host.
A Windows student uses WSL. Install `make`, `qemu-user`, and Zig 0.16.0 in WSL.
No supported macOS path for QEMU user mode is known. Treat this as an open limitation.

The course operating system later uses Clang and QEMU system mode, `qemu-system-riscv32`.
That is a different runtime.

## Continuous integration

The workflow `.github/workflows/lab0.yml` scores the submitted commit.
It prints the full commit hash before it scores.
The score from the workflow is the exercise score.

## For the instructor

Run `bin/review-fork <fork-url> <commit>` to check one submission.
The tool checks out the submitted commit first.
It lists each changed protected path.
The allowlist holds the solution files of the course tag.
It also permits `README.md`, `completed.txt`, and `EXPLANATIONS.md`.
Every other added, deleted, or changed path is protected.
The tool builds each solution with the exercise Makefile.
It reads the assembled object, so a macro or a directive cannot hide a system call.
It warns about a system call, an unexpected library call, and forgery text.
A solution file that does not assemble also warns.
No exercise needs a system call or a library call.
The tool needs `llvm-objdump`, `llvm-nm`, and `llvm-strings`.
The tool stops with an error when one is missing.
It then runs `make test-lab0` at that commit.
Set `LAB0_COURSE_URL` to change the course repository.
Set `LAB0_COURSE_TAG` to change the baseline tag.
A solution can write and then jump to instruction bytes at run time.
A determined author can hide a system call in other ways.
That is the accepted residual risk. Read each flagged solution.

## Licence

The track keeps the upstream MIT licence. See [LICENSE](LICENSE).
