#!/usr/bin/env bash
# Scoring tests for `make test-lab0` and for `bin/review-fork`.
#
# Each case builds a small temporary submission, runs `make test-lab0`, and
# checks the printed totals and the exit code.
# The review cases build a small local repository and run `bin/review-fork`.
# Requires: bash, make, qemu-riscv32, zig, git, python3.

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
  mkdir -p "${RF_WORK}/exercises/practice/leap" "${RF_WORK}/exercises/practice/two-fer"
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
# exactly .text, but the .text. prefix makes it executable. The aid must warn
# about the raw directive.
case_review_fork_raw_text_subsection() {
  rf_repo raw-text-subsection
  printf '.section .text.attack,"ax",@progbits\n.global leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        .word 0x00000073\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a raw directive"
}

# The same, with a .4byte directive and an x flag on a section that is not
# named .text.
case_review_fork_flagged_data_subsection() {
  rf_repo flagged-data-subsection
  printf '.section .foo,"ax",@progbits\n.global leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        .4byte 0x00000073\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a raw directive"
}

# A solution that uses .pushsection. The aid warns, because tracking the
# pushed section exactly is not worth the risk.
case_review_fork_pushsection() {
  rf_repo pushsection
  printf '.text\n.global leap_year\nleap_year:\n        li a0, 0\n        ret\n.pushsection .foo,"ax",@progbits\n.popsection\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a raw directive"
}

# A correct solution with a .word lookup table in .rodata and no x flag. The
# aid must not warn.
case_review_fork_data_table() {
  rf_repo data-table
  printf '.text\n.global leap_year\nleap_year:\n        li a0, 0\n        ret\n.section .rodata\ntable:\n        .word 1\n        .word 2\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_no_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a raw directive"
}

# The assembler accepts directives and mnemonics in any case. A raw .WORD in
# an upper-case .TEXT section must warn.
case_review_fork_upper_text() {
  rf_repo upper-text
  printf '.TEXT\n.GLOBL leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        .WORD 0x00000073\n        ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a raw directive"
}

# An upper-case ECALL must warn.
case_review_fork_upper_ecall() {
  rf_repo upper-ecall
  printf '.text\n.globl leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        ECALL\n        ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a raw directive"
}

# scall is an old alias of ecall. It must warn.
case_review_fork_scall() {
  rf_repo scall
  printf '.text\n.globl leap_year\nleap_year:\n        li a0, 0\n        li a7, 93\n        scall\n        ret\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a raw directive"
}

# A .macro that wraps a raw directive in .rodata. Only the macro rule can fire,
# so the case tests that branch.
case_review_fork_macro() {
  rf_repo macro
  printf '.text\n.globl leap_year\nleap_year:\n        li a0, 0\n        ret\n.section .rodata\n.macro emit\n        .4byte 0x00000073\n.endm\n' \
    > "${RF_WORK}/exercises/practice/leap/leap.S"
  local commit; commit="$(rf_submit)"
  rf_run "${commit}"
  expect_line "[WARNING] exercises/practice/leap/leap.S holds a system call or a raw directive"
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
run_case review-fork-pushsection case_review_fork_pushsection
run_case review-fork-data-table case_review_fork_data_table
run_case review-fork-upper-text case_review_fork_upper_text
run_case review-fork-upper-ecall case_review_fork_upper_ecall
run_case review-fork-scall case_review_fork_scall
run_case review-fork-macro case_review_fork_macro

printf '\n=== SUMMARY: %d passed, %d failed ===\n' "${pass}" "${fail}"
if (( fail > 0 )); then
  printf 'failed cases:\n'
  printf '  %s\n' "${failed_cases[@]}"
  exit 1
fi
exit 0
