# Tools for contributors

Students need only the tools in [INSTALLATION.md](INSTALLATION.md).
Contributors need a few more, because the track's scripts use them:

- `git`, to clone the repository and open pull requests.
- `jq`, used by `bin/verify-exercises` and `bin/add-practice-exercise`.
- `curl`, used by `bin/fetch-configlet`.
- Python 3.11 or later, for the test generator.
- `clang-format`, which the test generator runs on the files it writes.
- `pre-commit`, which runs the repository's checks before each commit.

Install them with the command for your distribution, then follow the steps under "Set up the repository".

## Debian / Ubuntu

```shell
sudo apt install git jq curl clang-format pre-commit
```

## Fedora

```shell
sudo dnf install git jq curl pre-commit clang-tools-extra diffutils
```

## Arch Linux

```shell
sudo pacman -S git jq curl pre-commit clang diffutils
```

## openSUSE Tumbleweed

```shell
sudo zypper install git jq curl python3-pre-commit clang-tools diffutils
```

## Set up the repository

From the repository root:

```shell
bin/fetch-configlet
bin/configlet info
pre-commit install
pre-commit run --all-files
```
