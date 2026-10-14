#!/usr/bin/env bash
# Scoring tests for `make test-lab0`.
#
# Each case builds a small temporary submission, runs `make test-lab0`, and
# checks the printed totals and the exit code.
# Requires: bash, make, qemu-riscv32, zig, python3.

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
run_case catalog-freshness case_catalog_freshness
run_case missing-explanation case_missing_explanation

printf '\n=== SUMMARY: %d passed, %d failed ===\n' "${pass}" "${fail}"
if (( fail > 0 )); then
  printf 'failed cases:\n'
  printf '  %s\n' "${failed_cases[@]}"
  exit 1
fi
exit 0
