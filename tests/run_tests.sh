#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0
EXIT_CODE=0

run_suite() {
  local suite="$1"
  local name
  name="$(basename "$suite" .sh)"

  printf '\n\033[1;36m━━━ %s ━━━\033[0m\n' "$name"

  local output rc=0
  output="$(bash "$suite" 2>&1)" || rc=$?

  printf '%s\n' "$output"

  local pass fail skip
  pass=$(echo "$output" | grep -c '✓' || true)
  fail=$(echo "$output" | grep -c '✗' || true)
  skip=$(echo "$output" | grep -c '○' || true)

  TOTAL_PASS=$((TOTAL_PASS + pass))
  TOTAL_FAIL=$((TOTAL_FAIL + fail))
  TOTAL_SKIP=$((TOTAL_SKIP + skip))

  if [[ "$rc" -ne 0 ]]; then
    EXIT_CODE=1
  fi
}

suites=(
  "$SCRIPT_DIR/test_syntax.sh"
  "$SCRIPT_DIR/test_utils.sh"
  "$SCRIPT_DIR/test_install.sh"
  "$SCRIPT_DIR/test_checks.sh"
  "$SCRIPT_DIR/test_os_linux.sh"
)

# Allow running a single suite: bash run_tests.sh test_utils
if [[ $# -gt 0 ]]; then
  suites=()
  for arg in "$@"; do
    suites+=("$SCRIPT_DIR/${arg}.sh")
  done
fi

for suite in "${suites[@]}"; do
  if [[ -f "$suite" ]]; then
    run_suite "$suite"
  else
    printf '\033[31mSuite not found: %s\033[0m\n' "$suite"
    EXIT_CODE=1
  fi
done

printf '\n\033[1m════════════════════════════════\033[0m\n'
printf '\033[1mTotal: \033[32m%d passed\033[0m' "$TOTAL_PASS"
[[ "$TOTAL_FAIL" -eq 0 ]] || printf ', \033[31m%d failed\033[0m' "$TOTAL_FAIL"
[[ "$TOTAL_SKIP" -eq 0 ]] || printf ', \033[33m%d skipped\033[0m' "$TOTAL_SKIP"
printf ' (%d tests)\033[0m\n\n' "$((TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP))"

exit $EXIT_CODE
