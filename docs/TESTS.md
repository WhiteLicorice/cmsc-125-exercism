# Tests

## Running tests

To run the tests, execute the following command in the exercise directory:

```shell
make
```

This assembles your solution, compiles the tests, links them into a RISC-V program and runs it under `qemu-riscv32`.
The program prints a line for each test, showing whether it passed, failed or was ignored, then a summary.

## Solving the exercise

Solving an exercise means making all its tests pass.
By default, only one test (the first one) is executed when you run the tests.
This is intentional, as it allows you to focus on just making that one test pass.
Once it passes, you can enable the next test by removing the `TEST_IGNORE();` line.
When all tests have been enabled and your implementation makes them all pass, you'll have solved the exercise!
