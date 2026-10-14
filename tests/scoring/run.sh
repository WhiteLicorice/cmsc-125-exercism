#!/usr/bin/env bash
# Scoring tests for `make test-lab0` and for `bin/review-fork`.
#
# Each case builds a small temporary submission, runs `make test-lab0`, and
# checks the printed totals and the exit code.
# The review cases build a small local repository and run `bin/review-fork`.
# Requires: bash, make, qemu-riscv32, zig, git, llvm, python3.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TIMEOUT="${LAB0_TIMEOUT:-60}"
WORK="$(mktemp -d -t lab0-scoring-XXXXXX)"
trap 'rm -rf "${WORK}"' EXIT

pass=0
fail=0
declare -a failed_cases=()

LAST_OUT=""
LAST_RC=0

# Slugs of one classification, at most COUNT of them, in catalog order.
first_of() {
  awk -F'\t' -v c="$1" -v n="$2" '$4==c && k<n {print $1; k++}' "${REPO}/catalog.tsv"
}

# Build a submission directory that holds only the needed files.
new_submission() {
  local name="$1"; shift
  local dir="${WORK}/${name}"
  mkdir -p "${dir}/exercises/practice"
  cp "${REPO}/Makefile" "${dir}/Makefile"
  cp "${REPO}/catalog.tsv" "${dir}/catalog.tsv"
  cp -r "${REPO}/bin" "${dir}/bin"
  local slug
  for slug in "$@"; do
    cp -r "${REPO}/exercises/practice/${slug}" "${dir}/exercises/practice/${slug}"
  done
  : > "${dir}/completed.txt"
  printf '# Explanations\n\nAdd one entry for each claimed exercise.\n' > "${dir}/EXPLANATIONS.md"
  printf '%s\n' "${dir}"
}

claim() {
  local dir="$1"; shift
  printf '%s\n' "$@" > "${dir}/completed.txt"
}

use_example() {
  local dir="$1" slug="$2"
  cp "${dir}/exercises/practice/${slug}/.meta/example.S" \
     "${dir}/exercises/practice/${slug}/${slug//-/_}.S"
}

# Copy the leap example and print a diagnostic on each call. The diagnostic
# holds ":FAIL:" or ":IGNORE:" text. It is not a Unity result record.
add_diagnostic_solution() {
  local dir="$1" message="$2"
  local ex="${dir}/exercises/practice/leap/.meta/example.S"
  local out="${dir}/exercises/practice/leap/leap.S"
  awk '
    { print }
    $0 == "leap_year:" {
      print "        addi    sp, sp, -16"
      print "        sw      ra, 12(sp)"
      print "        sw      a0, 8(sp)"
      print "        la      a0, diagnostic"
      print "        call    puts"
      print "        lw      a0, 8(sp)"
      print "        lw      ra, 12(sp)"
      print "        addi    sp, sp, 16"
    }
  ' "${ex}" > "${out}"
  printf '\n.section .rodata\ndiagnostic:\n        .asciz "%s"\n' "${message}" >> "${out}"
}

# Run the scorer. Set LAST_OUT and LAST_RC. The optional second argument sets
# the per-exercise time limit in seconds.
run_lab0() {
  local dir="$1" limit="${2:-${TIMEOUT}}"
  LAST_OUT="$(cd "${dir}" && LAB0_TIMEOUT="${limit}" make test-lab0 2>&1)"
  LAST_RC=$?
}

expect_rc() {
  [ "${LAST_RC}" -eq "$1" ] || { echo "  expected exit $1, got ${LAST_RC}"; return 1; }
}

# make returns 2 when a recipe fails, so check a non-zero exit, not one value.
expect_rc_nonzero() {
  [ "${LAST_RC}" -ne 0 ] || { echo "  expected a non-zero exit, got ${LAST_RC}"; return 1; }
}

expect_line() {
  grep -qF -- "$1" <<< "${LAST_OUT}" || { echo "  missing line: $1"; return 1; }
}

expect_no_line() {
  if grep -qF -- "$1" <<< "${LAST_OUT}"; then
    echo "  unexpected line: $1"; return 1
  fi
}

run_case() {
  local name="$1"; shift
  printf '\n=== CASE %s ===\n' "${name}"
  if "$@"; then
    printf 'RESULT: PASS %s\n' "${name}"
    pass=$((pass + 1))
  else
    printf 'RESULT: FAIL %s\n' "${name}"
    fail=$((fail + 1))
    failed_cases+=("${name}")
  fi
}

case_zero() {
  local dir; dir="$(new_submission zero)"
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "TOTAL POINTS: 0" && expect_line "TOTAL MARKS: 0"
}

case_points_80() {
  local dir s; local -a slugs
  mapfile -t slugs < <(first_of easy 8)
  dir="$(new_submission p80 "${slugs[@]}")"
  for s in "${slugs[@]}"; do use_example "${dir}" "${s}"; done
  claim "${dir}" "${slugs[@]}"
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "TOTAL POINTS: 80" && expect_line "TOTAL MARKS: 24"
}

case_points_100() {
  local dir s; local -a slugs
  mapfile -t slugs < <(first_of easy 4; first_of medium 4)
  dir="$(new_submission p100 "${slugs[@]}")"
  for s in "${slugs[@]}"; do use_example "${dir}" "${s}"; done
  claim "${dir}" "${slugs[@]}"
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "TOTAL POINTS: 100" && expect_line "TOTAL MARKS: 30"
}

case_points_150() {
  local dir s; local -a slugs
  mapfile -t slugs < <(first_of medium 10)
  dir="$(new_submission p150 "${slugs[@]}")"
  for s in "${slugs[@]}"; do use_example "${dir}" "${s}"; done
  claim "${dir}" "${slugs[@]}"
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "TOTAL POINTS: 150" && expect_line "TOTAL MARKS: 45"
}

case_easy_only() {
  local dir s; local -a slugs
  mapfile -t slugs < <(first_of easy 10)
  dir="$(new_submission easy-only "${slugs[@]}")"
  for s in "${slugs[@]}"; do use_example "${dir}" "${s}"; done
  claim "${dir}" "${slugs[@]}"
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "TOTAL POINTS: 100" && expect_line "TOTAL MARKS: 30"
}

case_mixed() {
  local dir s; local -a slugs
  mapfile -t slugs < <(first_of easy 2; first_of medium 2; first_of hard 2)
  dir="$(new_submission mixed "${slugs[@]}")"
  for s in "${slugs[@]}"; do use_example "${dir}" "${s}"; done
  claim "${dir}" "${slugs[@]}"
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "TOTAL POINTS: 90" && expect_line "TOTAL MARKS: 27"
}

case_failed_claim() {
  local dir; dir="$(new_submission failed hello-world leap two-fer)"
  use_example "${dir}" leap
  use_example "${dir}" two-fer
  claim "${dir}" hello-world leap two-fer
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "TOTAL POINTS: 20" && expect_line "TOTAL MARKS: 6" \
    && expect_line "leap: PASS" && expect_line "two-fer: PASS" && expect_line "hello-world: FAIL"
}

case_invalid_slug() {
  local dir; dir="$(new_submission invalid)"
  claim "${dir}" not-a-real-exercise
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "invalid slug: not-a-real-exercise" && expect_line "TOTAL POINTS: 0"
}

case_duplicate_slug() {
  local dir; dir="$(new_submission duplicate leap)"
  use_example "${dir}" leap
  claim "${dir}" leap leap
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "duplicate slug: leap" && expect_line "TOTAL POINTS: 10" && expect_line "TOTAL MARKS: 3"
}

case_skipped_test() {
  local dir; dir="$(new_submission skipped leap two-fer)"
  use_example "${dir}" leap
  use_example "${dir}" two-fer
  sed -i '/void test_year_divisible_by_4_not_divisible_by_100_in_leap_year(void) {/a\    TEST_IGNORE();' \
    "${dir}/exercises/practice/leap/leap_test.c"
  claim "${dir}" leap two-fer
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "leap: FAIL" && expect_line "reason=skipped" \
    && expect_line "two-fer: PASS" && expect_line "TOTAL POINTS: 10" && expect_line "TOTAL MARKS: 3"
}

case_compile_failure() {
  local dir; dir="$(new_submission build hello-world)"
  printf 'this is not valid assembly\n' > "${dir}/exercises/practice/hello-world/hello_world.S"
  claim "${dir}" hello-world
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "hello-world: FAIL" && expect_line "reason=build" && expect_line "TOTAL POINTS: 0"
}

case_crash() {
  local dir; dir="$(new_submission crash hello-world)"
  printf '.text\n.global hello\nhello:\n    li a0, 0\n    lw a0, 0(a0)\n    ret\n' \
    > "${dir}/exercises/practice/hello-world/hello_world.S"
  claim "${dir}" hello-world
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "hello-world: FAIL" && expect_line "reason=crash" && expect_line "TOTAL POINTS: 0"
}

case_timeout() {
  local dir; dir="$(new_submission timeout hello-world)"
  printf '.text\n.global hello\nhello:\n    j hello\n' \
    > "${dir}/exercises/practice/hello-world/hello_world.S"
  claim "${dir}" hello-world
  run_lab0 "${dir}" 2
  expect_rc_nonzero && expect_line "hello-world: FAIL" && expect_line "reason=timeout" && expect_line "TOTAL POINTS: 0"
}

# A solution that prints its own Unity summary and exits 0. The scorer must
# not accept it, because no test line is real.
case_forged_summary() {
  local dir; dir="$(new_submission forged leap)"
  cat > "${dir}/exercises/practice/leap/leap.S" <<'ASM'
.section .rodata
msg:
    .ascii "\n8 Tests 0 Failures 0 Ignored\nOK\n"

.text
.global leap_year
leap_year:
    li a0, 1
    la a1, msg
    li a2, 33
    li a7, 64
    ecall
    li a0, 0
    li a7, 93
    ecall
ASM
  claim "${dir}" leap
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "leap: FAIL" && expect_line "reason=forged" \
    && expect_line "TOTAL POINTS: 0" && expect_line "TOTAL MARKS: 0"
}

# A passing solution. It prints ":FAIL:" in a diagnostic. The scorer must not
# read that text as a test result.
case_diagnostic_fail() {
  local dir; dir="$(new_submission diagnostic-fail leap)"
  add_diagnostic_solution "${dir}" "passing solution message:FAIL: harmless"
  claim "${dir}" leap
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "leap: PASS" && expect_line "TOTAL POINTS: 10" && expect_line "TOTAL MARKS: 3"
}

# The same, with ":IGNORE:" in the diagnostic.
case_diagnostic_ignore() {
  local dir; dir="$(new_submission diagnostic-ignore leap)"
  add_diagnostic_solution "${dir}" "passing solution message:IGNORE: harmless"
  claim "${dir}" leap
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "leap: PASS" && expect_line "TOTAL POINTS: 10" && expect_line "TOTAL MARKS: 3"
}

# The reviewer's catalog rewrite. The leap solution rewrites
# "../../../catalog.tsv" and gives two-fer 1000 points. It then computes the
# correct leap result. The scorer must award at most 20 points and must stop
# with reason=tamper.
case_catalog_write() {
  local dir; dir="$(new_submission catalog-write leap two-fer)"
  use_example "${dir}" two-fer
  cat > "${dir}/exercises/practice/leap/leap.S" <<'ASM'
.text
.global leap_year
leap_year:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      a0, 8(sp)
        li      a0, -100
        la      a1, catalog_path
        li      a2, 577
        li      a3, 0
        li      a7, 56
        ecall
        sw      a0, 4(sp)
        la      a1, catalog_data
        li      a2, catalog_end - catalog_data
        li      a7, 64
        ecall
        lw      a0, 4(sp)
        li      a7, 57
        ecall
        lw      a0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16

        li      t0, 100
        rem     t1, a0, t0
        bnez    t1, .test
        div     a0, a0, t0
.test:
        andi    a0, a0, 3
        slti    a0, a0, 1
        ret

.section .rodata
catalog_path:
        .asciz "../../../catalog.tsv"
catalog_data:
        .ascii "slug\tname\tdifficulty\tclassification\tpoints\nleap\tLeap\t1\teasy\t10\ntwo-fer\tTwo Fer\t1\teasy\t1000\n"
catalog_end:
ASM
  claim "${dir}" leap two-fer
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "reason=tamper" \
    && expect_line "TOTAL POINTS: 0" && expect_line "TOTAL MARKS: 0"
}

# A solution that rewrites the next claim's test file through a relative path.
# The leap solution truncates "../two-fer/two_fer_test.c". The next claim uses
# the correct example. The write must not change the next claim's result.
case_relative_test_write() {
  local dir; dir="$(new_submission relative-test-write leap two-fer)"
  use_example "${dir}" two-fer
  cat > "${dir}/exercises/practice/leap/leap.S" <<'ASM'
.text
.global leap_year
leap_year:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      a0, 8(sp)
        li      a0, -100
        la      a1, next_test
        li      a2, 577
        li      a3, 0
        li      a7, 56
        ecall
        bltz    a0, 1f
        li      a7, 57
        ecall
1:
        lw      a0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16

        li      t0, 100
        rem     t1, a0, t0
        bnez    t1, .test
        div     a0, a0, t0
.test:
        andi    a0, a0, 3
        slti    a0, a0, 1
        ret

.section .rodata
next_test:
        .asciz "../two-fer/two_fer_test.c"
ASM
  claim "${dir}" leap two-fer
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "leap: PASS" && expect_line "two-fer: PASS" \
    && expect_line "TOTAL POINTS: 20" && expect_line "TOTAL MARKS: 6"
}

# A solution that rewrites a protected file through an absolute repository
# path. The scorer must stop with reason=tamper.
case_absolute_path_write() {
  local dir; dir="$(new_submission absolute-path leap)"
  cat > "${dir}/exercises/practice/leap/leap.S" <<ASM
.text
.global leap_year
leap_year:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      a0, 8(sp)
        li      a0, -100
        la      a1, target
        li      a2, 577
        li      a3, 0
        li      a7, 56
        ecall
        sw      a0, 4(sp)
        la      a1, payload
        li      a2, payload_end - payload
        li      a7, 64
        ecall
        lw      a0, 4(sp)
        li      a7, 57
        ecall
        lw      a0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16

        li      t0, 100
        rem     t1, a0, t0
        bnez    t1, .test
        div     a0, a0, t0
.test:
        andi    a0, a0, 3
        slti    a0, a0, 1
        ret

.section .rodata
target:
        .asciz "${dir}/catalog.tsv"
payload:
        .ascii "tampered\n"
payload_end:
ASM
  claim "${dir}" leap
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "reason=tamper" \
    && expect_line "TOTAL POINTS: 0" && expect_line "TOTAL MARKS: 0"
}

# A missing completed.txt must still print the aggregate lines.
case_missing_completed() {
  local dir; dir="$(new_submission missing-completed leap)"
  rm -f "${dir}/completed.txt"
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "TOTAL POINTS: 0" && expect_line "TOTAL MARKS: 0"
}

# A missing catalog.tsv must still print the aggregate lines.
case_missing_catalog() {
  local dir; dir="$(new_submission missing-catalog leap)"
  rm -f "${dir}/catalog.tsv"
  run_lab0 "${dir}"
  expect_rc_nonzero && expect_line "TOTAL POINTS: 0" && expect_line "TOTAL MARKS: 0"
}

catalog_is_fresh() {
  local tmp; tmp="$(mktemp -d "${WORK}/fresh-XXXXXX")"
  (cd "${REPO}" && bin/generate-catalog "${tmp}") >/dev/null 2>&1 || return 2
  cmp -s "${REPO}/CATALOG.md" "${tmp}/CATALOG.md" &&
    cmp -s "${REPO}/catalog.tsv" "${tmp}/catalog.tsv"
}

case_catalog_freshness() {
  catalog_is_fresh || { echo "  committed catalog differs from a fresh generation"; return 1; }
  local tmp; tmp="$(mktemp -d "${WORK}/tamper-XXXXXX")"
  (cd "${REPO}" && bin/generate-catalog "${tmp}") >/dev/null 2>&1 || return 1
  printf 'tampered\n' >> "${tmp}/catalog.tsv"
  if cmp -s "${REPO}/catalog.tsv" "${tmp}/catalog.tsv"; then
    echo "  the freshness check did not detect a changed catalog"
    return 1
  fi
}

case_missing_explanation() {
  local dir s; local -a slugs
  mapfile -t slugs < <(first_of easy 10)
  dir="$(new_submission missing-exp "${slugs[@]}")"
  for s in "${slugs[@]}"; do use_example "${dir}" "${s}"; done
  claim "${dir}" "${slugs[@]}"
  run_lab0 "${dir}"
  expect_rc 0 && expect_line "TOTAL POINTS: 100" && expect_line "warning: no explanation for hello-world"
}

# ---- review-fork cases ----------------------------------------------------

RF_BARE=""
RF_WORK=""

# A bare repository with a clean default branch and the course tag v1.0.
rf_repo() {
  local name="$1"
  RF_BARE="${WORK}/rf-${name}.git"
  RF_WORK="${WORK}/rf-${name}-work"
  git init --quiet --bare "${RF_BARE}" >/dev/null 2>&1
  git init --quiet "${RF_WORK}" >/dev/null 2>&1
  git -C "${RF_WORK}" checkout --quiet -b main >/dev/null 2>&1
  git -C "${RF_WORK}" config user.email review@example.com
  git -C "${RF_WORK}" config user.name review
  git -C "${RF_WORK}" config commit.gpgsign false
  local slug
  for slug in leap two-fer; do
    mkdir -p "${RF_WORK}/exercises/practice/${slug}/.meta"
    cp "${REPO}/exercises/practice/${slug}/Makefile" \
      "${RF_WORK}/exercises/practice/${slug}/Makefile"
    cp "${REPO}/exercises/practice/${slug}/.meta/example.S" \
      "${RF_WORK}/exercises/practice/${slug}/.meta/example.S"
  done
  printf '.text\n.global leap_year\nleap_year:\n        li a0, 0\n        ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  printf '.text\n.global two_fer\ntwo_fer:\n        ret\n' \
    > "${RF_WORK}/exercises/practice/two-fer/two_fer.S"
  git -C "${RF_WORK}" add -A
  git -C "${RF_WORK}" commit --quiet -m clean
  git -C "${RF_WORK}" tag v1.0
  git -C "${RF_WORK}" push --quiet "${RF_BARE}" refs/heads/main refs/tags/v1.0
  git -C "${RF_BARE}" symbolic-ref HEAD refs/heads/main
}

# Commit the working tree as branch "submitted". Print the commit hash.
rf_submit() {
  git -C "${RF_WORK}" checkout --quiet -b submitted
  git -C "${RF_WORK}" add -A
  git -C "${RF_WORK}" commit --quiet -m submitted
  git -C "${RF_WORK}" push --quiet "${RF_BARE}" refs/heads/submitted
  git -C "${RF_WORK}" rev-parse HEAD
}

# Run the review aid against the bare repository. Set LAST_OUT and LAST_RC.
rf_run() {
  local commit="$1"
  LAST_OUT="$(LAB0_COURSE_URL="${RF_BARE}" LAB0_COURSE_TAG=v1.0 \
    "${REPO}/bin/review-fork" "${RF_BARE}" "${commit}" 2>&1)"
  LAST_RC=$?
}

# A bare repository that holds every course exercise. The tag v1.0 holds the
# course stub solutions. It is used for the example negative control.
rf_all_repo() {
  local name="$1"
  RF_BARE="${WORK}/rf-${name}.git"
  RF_WORK="${WORK}/rf-${name}-work"
  git init --quiet --bare "${RF_BARE}" >/dev/null 2>&1
  git init --quiet "${RF_WORK}" >/dev/null 2>&1
  git -C "${RF_WORK}" checkout --quiet -b main >/dev/null 2>&1
  git -C "${RF_WORK}" config user.email review@example.com
  git -C "${RF_WORK}" config user.name review
  git -C "${RF_WORK}" config commit.gpgsign false
  local dir slug snake
  while IFS= read -r dir; do
    slug="$(basename "${dir}")"
    snake="${slug//-/_}"
    mkdir -p "${RF_WORK}/exercises/practice/${slug}/.meta"
    cp "${dir}/Makefile" "${RF_WORK}/exercises/practice/${slug}/Makefile"
    cp "${dir}/.meta/example.S" \
      "${RF_WORK}/exercises/practice/${slug}/.meta/example.S"
    printf '.text\n.global %s\n%s:\n        ret\n' "${snake}" "${snake}" \
      > "${RF_WORK}/exercises/practice/${slug}/${snake}.S"
  done < <(find "${REPO}/exercises/practice" -mindepth 1 -maxdepth 1 -type d | sort)
  git -C "${RF_WORK}" add -A
  git -C "${RF_WORK}" commit --quiet -m clean
  git -C "${RF_WORK}" tag v1.0
  git -C "${RF_WORK}" push --quiet "${RF_BARE}" refs/heads/main refs/tags/v1.0
  git -C "${RF_BARE}" symbolic-ref HEAD refs/heads/main
}

# Submit the current work tree and check the system-call warning line.
rf_expect_syscall() {
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a breakpoint"
}

# The default branch is clean. The submitted commit holds a forged solution.
# The aid must scan the submitted commit and warn.
case_review_fork_submitted_commit() {
  rf_repo submitted-commit
  printf '.text\n.global leap_year\nleap_year:\n        li a0, 1\n        ecall\n        .word 0x00000073\n        ret\n.section .rodata\nmsg:\n        .ascii "Tests"\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S"
}

# A solution path that is not a course exercise is protected.
case_review_fork_unknown_exercise() {
  rf_repo unknown-exercise
  mkdir -p "${RF_WORK}/exercises/practice/not-an-exercise"
  printf '.text\n.global not_an_exercise\nnot_an_exercise:\n        ret\n' \
    > "${RF_WORK}/exercises/practice/not-an-exercise/not_an_exercise.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_rc_nonzero && expect_line "exercises/practice/not-an-exercise/not_an_exercise.S"
}

# An extra .S file in a real exercise folder is protected.
case_review_fork_extra_solution() {
  rf_repo extra-solution
  printf '.text\n.global extra\nextra:\n        ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap_extra.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_rc_nonzero && expect_line "exercises/practice/leap/leap_extra.S"
}

# A raw instruction in an executable text subsection. The section name is not
# exactly .text, but the .text. prefix makes it executable. The object scan
# must warn.
case_review_fork_raw_text_subsection() {
  rf_repo raw-text-subsection
  printf '.section .text.attack,"ax",@progbits\n.global leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        .word 0x00000073\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# The same, with a .4byte directive and an x flag on a section that is not
# named .text.
case_review_fork_flagged_data_subsection() {
  rf_repo flagged-data-subsection
  printf '.section .foo,"ax",@progbits\n.global leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        .4byte 0x00000073\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# A correct solution with a .word lookup table in .rodata and no x flag. The
# aid must not warn.
case_review_fork_data_table() {
  rf_repo data-table
  printf '.text\n.global leap_year\nleap_year:\n        li a0, 0\n        ret\n.section .rodata\ntable:\n        .word 1\n        .word 2\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_rc 0 && expect_no_line "[WARNING]"
}

# The assembler accepts an upper-case directive. An upper-case .WORD that
# emits the exit system call must warn.
case_review_fork_upper_word() {
  rf_repo upper-word
  printf '.text\n.globl leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        .WORD 0x00000073\n        ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# An upper-case ECALL must warn.
case_review_fork_upper_ecall() {
  rf_repo upper-ecall
  printf '.text\n.globl leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        ECALL\n        ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# scall is an old alias of ecall. It assembles to the same instruction, so the
# object scan warns.
case_review_fork_scall() {
  rf_repo scall
  printf '.text\n.globl leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        scall\n        ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# A .macro that wraps .4byte and is expanded in .text. The expansion emits the
# exit system call, so only the object scan can warn.
case_review_fork_macro() {
  rf_repo macro
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.text
.globl leap_year
.macro emit
        .4byte 0x00000073
.endm
leap_year:
        li a0, 0
        emit
        ret
ASM
  rf_expect_syscall
}

# .uleb128 emits the four bytes of the exit system call. The source holds no
# mnemonic, byte directive, or section trick.
case_review_fork_uleb128() {
  rf_repo uleb128
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.text
.globl leap_year
leap_year:
 li a0,0
 li a7,93
 .uleb128 115,0,0,0
ASM
  rf_expect_syscall
}

# .space emits the bytes.
case_review_fork_space() {
  rf_repo space
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.text
.globl leap_year
leap_year:
 li a0,0
 li a7,93
 .space 1,115
 .space 3,0
ASM
  rf_expect_syscall
}

# .zero emits the bytes.
case_review_fork_zero() {
  rf_repo zero
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.text
.globl leap_year
leap_year:
 li a0,0
 li a7,93
 .zero 1,115
 .zero 3,0
ASM
  rf_expect_syscall
}

# The C preprocessor builds the ecall mnemonic by token pasting.
case_review_fork_cpp_paste() {
  rf_repo cpp-paste
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
#define cat(a,b) a##b
.text
.globl leap_year
leap_year:
 li a0,0
 li a7,93
 cat(e,call)
ASM
  rf_expect_syscall
}

# A re-entered executable section keeps its x flag.
case_review_fork_section_reentry() {
  rf_repo section-reentry
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.section .payload,"ax",@progbits
.text
.section .payload
.globl leap_year
leap_year:
 li a0,0
 li a7,93
 .word 0x73
ASM
  rf_expect_syscall
}

# A quoted section name with an x flag.
case_review_fork_quoted_section() {
  rf_repo quoted-section
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.section "payload","ax",@progbits
.globl leap_year
leap_year:
 li a0,0
 li a7,93
 .word 0x73
ASM
  rf_expect_syscall
}

# A label before the .text directive.
case_review_fork_label_section() {
  rf_repo label-section
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.data
marker: .text
.globl leap_year
leap_year:
 li a0,0
 li a7,93
 .word 0x73
ASM
  rf_expect_syscall
}

# A .data directive inside a block comment does not leave the text section.
case_review_fork_comment_section() {
  rf_repo comment-section
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.text
.globl leap_year
leap_year:
 li a0,0
 li a7,93
/*
.data
*/
 .word 0x73
ASM
  rf_expect_syscall
}

# A libc call is an undefined symbol. The example object gives the allowed set,
# so a call that the example does not make must warn.
case_review_fork_libc_call() {
  rf_repo libc-call
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.text
.globl leap_year
leap_year:
        addi sp, sp, -16
        sw ra, 12(sp)
        la a0, msg
        call write
        lw ra, 12(sp)
        addi sp, sp, 16
        li a0, 0
        ret
.section .rodata
msg:
        .asciz "hi"
ASM
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S calls an unexpected symbol: write"
}

# The preprocessor builds the forgery text. The source holds none of the words,
# but the object strings do.
case_review_fork_forge_text() {
  rf_repo forge-text
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
#define str(x) #x
#define xstr(x) str(x)
#define cat(a,b) a##b
#define T cat(T,ests)
#define F cat(F,ailures)
#define I cat(I,gnored)
.section .rodata
msg:
        .asciz xstr(8 T 0 F 0 I)
.text
.globl leap_year
leap_year:
        li a0, 0
        ret
ASM
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds text that can forge a test result"
}

# A literal ecall and then 20,000 nop instructions. The disassembly is large,
# so an early matcher exit must not hide the system call.
case_review_fork_large_ecall() {
  rf_repo large-ecall
  {
    printf '.text\n.globl leap_year\nleap_year:\n li a0,0\n li a7,93\n ecall\n'
    printf '.rept 20000\n nop\n.endr\n'
  } > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# Forgery text and then 20,000 padding strings. The string table is large, so
# an early matcher exit must not hide the forgery warning.
case_review_fork_large_forge() {
  rf_repo large-forge
  {
    printf '.text\n.globl leap_year\nleap_year:\n ret\n'
    printf '.section .rodata\n.asciz ":PASS"\n'
    printf '.rept 20000\n.asciz "padding"\n.endr\n'
  } > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds text that can forge a test result"
}

# A jump into the middle of a word. The word holds the ecall encoding at
# offset 2. A linear disassembly shows no ecall; the byte scan must warn.
case_review_fork_overlap() {
  rf_repo overlap
  printf '.text\n.globl leap_year\nleap_year:\n li a0,0\n li a7,93\n j payload+2\n.balign 4\npayload:\n .word 0x00730013\n .half 0\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# A label named ecall with no system call. The byte scan must not read a
# symbol name as an instruction.
case_review_fork_operand_name() {
  rf_repo operand-name
  printf '.text\n.globl leap_year\nleap_year:\n j ecall\necall:\n ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_rc 0 && expect_no_line "[WARNING]"
}

# A section name that holds a wildcard character. The scan must read the
# section by its header, not select it by name, so the word warns.
case_review_fork_wildcard_name() {
  rf_repo wildcard-name
  printf '.text\n.globl leap_year\nleap_year:\n ret\n.section "odd[1]","ax",@progbits\n.word 0x00000073\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# An executable section named "*" is empty. The system-call word sits in the
# non-executable .rodata. The scan must select by flag, not by name, so no
# warning appears.
case_review_fork_star_nonexec() {
  rf_repo star-nonexec
  printf '.text\n.globl leap_year\nleap_year:\n ret\n.section .rodata\n.word 0x00000073\n.section "*","ax",@progbits\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_rc 0 && expect_no_line "[WARNING]"
}

# A section name with two spaces in a row. A name split on spaces and rejoined
# loses a space, so the scan must not rebuild the name.
case_review_fork_double_space() {
  rf_repo double-space
  printf '.text\n.globl leap_year\nleap_year:\n ret\n.section "two  spaces","ax",@progbits\n.word 0x00000073\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# An executable section with no alloc flag. A binary conversion drops it, so
# the scan must read the bytes at the section offset in the file.
case_review_fork_nonalloc_x() {
  rf_repo nonalloc-x
  printf '.text\n.globl leap_year\nleap_year:\n ret\n.section custom,"x",@progbits\n.word 0x00000073\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# Two executable sections, one with a system call and one with a breakpoint.
# Both warn. The scan reads the object itself, so it needs no external tool.
case_review_fork_multi_ax() {
  rf_repo multi-ax
  cat > "${RF_WORK}/exercises/practice/leap/leap.S" <<'ASM'
.text
.globl leap_year
leap_year:
 ret
.section first,"ax",@progbits
.word 0x00000073
.section second,"ax",@progbits
.word 0x00100073
ASM
  rf_expect_syscall || return 1
  local obj="${RF_WORK}/exercises/practice/leap/leap.o"
  if ! make -C "${RF_WORK}/exercises/practice/leap" -s --no-print-directory leap.o \
      >/dev/null 2>&1; then
    echo "  cannot build the scan object"
    return 1
  fi
  local pydir; pydir="$(mktemp -d "${WORK}/path-XXXXXX")"
  ln -s "$(command -v python3)" "${pydir}/python3"
  local out
  if ! out="$(PATH="${pydir}" "${REPO}/bin/scan-object" "${obj}" 2>&1)"; then
    echo "  scan-object needs a tool outside python3: ${out}"
    return 1
  fi
  grep -qF "ecall" <<< "${out}" || { echo "  scan-object missed the system call: ${out}"; return 1; }
  grep -qF "ebreak" <<< "${out}" || { echo "  scan-object missed the breakpoint: ${out}"; return 1; }
}

# A compressed breakpoint in an executable section. The scan covers the
# compressed encoding, so the word warns.
case_review_fork_compressed_data() {
  rf_repo compressed-data
  printf '.text\n.globl leap_year\nleap_year:\n ret\n.section custom,"ax",@progbits\n.half 0x9002\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# A plain ebreak in .text. The assembler writes the compressed c.ebreak, so the
# scan must cover the compressed encoding to warn.
case_review_fork_ebreak() {
  rf_repo ebreak
  printf '.text\n.globl leap_year\nleap_year:\n li a0, 0\n ebreak\n ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  rf_expect_syscall
}

# A truncated object and a file that is not an ELF. The scan must stop with the
# inspect note, never report a clean scan.
case_scan_object_bad_object() {
  local dir; dir="$(mktemp -d "${WORK}/bad-obj-XXXXXX")"
  cp "${REPO}/exercises/practice/leap/Makefile" "${dir}/Makefile"
  cp "${REPO}/exercises/practice/leap/.meta/example.S" "${dir}/leap.S"
  if ! make -C "${dir}" -s --no-print-directory leap.o >/dev/null 2>&1; then
    echo "  cannot build the scan object"
    return 1
  fi
  head -c 40 "${dir}/leap.o" > "${dir}/truncated.o"
  printf 'not an object\n' > "${dir}/notelf.o"
  local out
  if out="$("${REPO}/bin/scan-object" "${dir}/truncated.o" 2>&1)"; then
    echo "  scanned a truncated object as clean: ${out}"
    return 1
  fi
  grep -qF "could not inspect the object" <<< "${out}" || { echo "  truncated object note missing: ${out}"; return 1; }
  if out="$("${REPO}/bin/scan-object" "${dir}/notelf.o" 2>&1)"; then
    echo "  scanned a non-ELF file as clean: ${out}"
    return 1
  fi
  grep -qF "could not inspect the object" <<< "${out}" || { echo "  non-ELF note missing: ${out}"; return 1; }
}

# Every example solution used as the student solution. None may warn. This
# replaces the single .rodata control and includes secret-handshake.
case_review_fork_examples() {
  rf_all_repo examples
  local dir slug snake
  while IFS= read -r dir; do
    slug="$(basename "${dir}")"
    snake="${slug//-/_}"
    cp "${dir}/.meta/example.S" \
      "${RF_WORK}/exercises/practice/${slug}/${snake}.S"
  done < <(find "${REPO}/exercises/practice" -mindepth 1 -maxdepth 1 -type d | sort)
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_rc 0 && expect_no_line "[WARNING]"
}

printf 'Scoring tests for make test-lab0 (default time limit %ss)\n' "${TIMEOUT}"

run_case zero case_zero
run_case invalid-slug case_invalid_slug
run_case duplicate-slug case_duplicate_slug
run_case points-80 case_points_80
run_case points-100 case_points_100
run_case points-150 case_points_150
run_case easy-only case_easy_only
run_case mixed case_mixed
run_case failed-claim case_failed_claim
run_case skipped-test case_skipped_test
run_case compile-failure case_compile_failure
run_case crash case_crash
run_case timeout case_timeout
run_case forged-summary case_forged_summary
run_case diagnostic-fail case_diagnostic_fail
run_case diagnostic-ignore case_diagnostic_ignore
run_case catalog-write case_catalog_write
run_case relative-test-write case_relative_test_write
run_case absolute-path-write case_absolute_path_write
run_case missing-completed case_missing_completed
run_case missing-catalog case_missing_catalog
run_case catalog-freshness case_catalog_freshness
run_case missing-explanation case_missing_explanation
run_case review-fork-submitted-commit case_review_fork_submitted_commit
run_case review-fork-unknown-exercise case_review_fork_unknown_exercise
run_case review-fork-extra-solution case_review_fork_extra_solution
run_case review-fork-raw-text-subsection case_review_fork_raw_text_subsection
run_case review-fork-flagged-data-subsection case_review_fork_flagged_data_subsection
run_case review-fork-data-table case_review_fork_data_table
run_case review-fork-upper-word case_review_fork_upper_word
run_case review-fork-upper-ecall case_review_fork_upper_ecall
run_case review-fork-scall case_review_fork_scall
run_case review-fork-macro case_review_fork_macro
run_case review-fork-uleb128 case_review_fork_uleb128
run_case review-fork-space case_review_fork_space
run_case review-fork-zero case_review_fork_zero
run_case review-fork-cpp-paste case_review_fork_cpp_paste
run_case review-fork-section-reentry case_review_fork_section_reentry
run_case review-fork-quoted-section case_review_fork_quoted_section
run_case review-fork-label-section case_review_fork_label_section
run_case review-fork-comment-section case_review_fork_comment_section
run_case review-fork-libc-call case_review_fork_libc_call
run_case review-fork-forge-text case_review_fork_forge_text
run_case review-fork-large-ecall case_review_fork_large_ecall
run_case review-fork-large-forge case_review_fork_large_forge
run_case review-fork-overlap case_review_fork_overlap
run_case review-fork-operand-name case_review_fork_operand_name
run_case review-fork-wildcard-name case_review_fork_wildcard_name
run_case review-fork-star-nonexec case_review_fork_star_nonexec
run_case review-fork-double-space case_review_fork_double_space
run_case review-fork-nonalloc-x case_review_fork_nonalloc_x
run_case review-fork-multi-ax case_review_fork_multi_ax
run_case review-fork-compressed-data case_review_fork_compressed_data
run_case review-fork-ebreak case_review_fork_ebreak
run_case scan-object-bad-object case_scan_object_bad_object
run_case review-fork-examples case_review_fork_examples

printf '\n=== SUMMARY: %d passed, %d failed ===\n' "${pass}" "${fail}"
if (( fail > 0 )); then
  printf 'failed cases:\n'
  printf '  %s\n' "${failed_cases[@]}"
  exit 1
fi
exit 0
