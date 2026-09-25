# How to contribute to the Exercism RISC-V track

Every contribution starts with a conversation on the [forum][forum].
Pull requests that were not discussed there first may be closed.

## Setting up your machine

1. Install `zig`, `make` and `qemu-riscv32` as described in [docs/INSTALLATION.md][installation].
1. Install the contributor tools as described in [docs/CONTRIBUTOR_TOOLS.md][contributor-tools].
1. Follow [Set up the repository][set-up-repository] in the same document.

---

## Test generator

Each exercise has a small Python module in `generators/exercises/<slug>.py` that turns canonical test case data into a [Unity][unity] test file.
`generators/generate <slug>` reads the canonical data that `bin/configlet info` fetched, applies any `tests.toml` exclusions, and writes `exercises/practice/<slug>/<slug>_test.c`, formatted with `clang-format`.

---

## Testing exercises

To check that an exercise's example solution passes its tests:

```sh
bin/verify-exercises <slug>
```

To run the same check inside the track's test runner image:

```sh
bin/verify-exercises-in-docker <slug>
```

---

## **Do you want to report a bug?**

- **Ensure the bug was not already reported** by searching the [forum][forum].

- If you're unable to find an open conversation addressing the problem, [open a new one][forum-new-topic].
  Be sure to include a **title and clear description**, the exercise concerned, as much relevant information as possible, and (when possible) a **code sample**.

## **Do you want to fix a bug?**

- **Ensure that the bug is reported (see above).**
  Only start fixing the bug when there is agreement on whether (and how) it should be fixed.

- Fix the bug and [submit a Pull Request][pr-guide] to this repository.

- Ensure the PR description clearly describes the problem and solution.
  Include a link to the bug's corresponding forum conversation.

- Before submitting, please read [Pull Requests][pr-other-guide] and [The Contributors' Guide to Pull Requests][pr-guide].

## **Do you intend to add a new feature or change an existing one?**

- **Ensure that the feature or change is discussed on the [forum][forum].**
  Only start adding the feature or change when there is agreement on whether (and how) it should be added or changed.

- Fork the exercism/risc-v repo, add the feature or change in your clone, and [submit a Pull Request][pr-guide] to this repository.

- Ensure the PR description clearly describes the problem and solution.
  Include a link to the corresponding forum conversation.

- Before submitting, please read [Pull Requests][pr-other-guide] and [The Contributors' Guide to Pull Requests][pr-guide].

## **Do you want to add an exercise?**

- **Ensure that someone else isn't already adding it**
    - search the [forum][forum] and the repository's [issues][gh-issues] and [pull requests][gh-pulls].

- If nobody is yet adding the exercise, [open a conversation on the forum][forum] and indicate you would like to add it.
  Propose the C prototype of each function the tests will call, for example `extern int leap_year(long year);`.
  The prototype is the contract every student writes against, so agree it before writing any code.

### Creating a new Practice Exercise

1. [Set up your machine](#setting-up-your-machine), if you have not already.
1. Run the scaffolding script from the repo root:
    ```sh
    bin/add-practice-exercise -a <github-username> -d <difficulty> <slug>
    ```
    The difficulty runs from 1 (easiest) to 10 (hardest).
1. Follow the next steps the script prints.
1. If the exercise's instructions need to differ from the problem specifications, add a `.docs/instructions.append.md` file rather than editing `instructions.md`; see the [instructions.append.md docs][instructions-append].
1. Commit, which runs the [pre-commit hooks][set-up-repository], and open one pull request per exercise with a link to the forum conversation.

---

[forum]: https://forum.exercism.org/c/programming/risc-v
[forum-new-topic]: https://forum.exercism.org/new-topic?category=risc-v
[gh-issues]: https://github.com/exercism/risc-v/issues
[gh-pulls]: https://github.com/exercism/risc-v/pulls
[pr-guide]: https://exercism.org/docs/building/github/contributors-pull-request-guide
[pr-other-guide]: https://exercism.org/docs/community/being-a-good-community-member/pull-requests
[unity]: https://www.throwtheswitch.org/unity
[instructions-append]: https://exercism.org/docs/building/tracks/practice-exercises#h-file-docs-instructions-append-md
[installation]: docs/INSTALLATION.md
[contributor-tools]: docs/CONTRIBUTOR_TOOLS.md
[set-up-repository]: docs/CONTRIBUTOR_TOOLS.md#set-up-the-repository
