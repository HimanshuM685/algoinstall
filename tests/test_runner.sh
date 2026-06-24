#!/usr/bin/env bash
set -uo pipefail

PASS=0
FAIL=0
SKIP=0
ERRORS=()

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-}"
  if [[ "$expected" == "$actual" ]]; then
    return 0
  fi
  ERRORS+=("expected '$expected', got '$actual'${msg:+ ($msg)}")
  return 1
}

assert_match() {
  local pattern="$1" actual="$2" msg="${3:-}"
  if [[ "$actual" =~ $pattern ]]; then
    return 0
  fi
  ERRORS+=("expected match '$pattern', got '$actual'${msg:+ ($msg)}")
  return 1
}

assert_exit() {
  local expected="$1"
  shift
  local actual
  ( "$@" ) >/dev/null 2>&1
  actual=$?
  if [[ "$expected" -eq "$actual" ]]; then
    return 0
  fi
  ERRORS+=("expected exit $expected, got $actual for: $*")
  return 1
}

run_test() {
  local name="$1"
  shift
  ERRORS=()
  local output
  output=$("$@" 2>&1) || true
  if [[ ${#ERRORS[@]} -eq 0 ]]; then
    printf '  \033[32m✓\033[0m %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf '  \033[31m✗\033[0m %s\n' "$name"
    for err in "${ERRORS[@]}"; do
      printf '    \033[31m→ %s\033[0m\n' "$err"
    done
    FAIL=$((FAIL + 1))
  fi
}

skip_test() {
  local name="$1" reason="${2:-}"
  printf '  \033[33m○\033[0m %s%s\n' "$name" "${reason:+ ($reason)}"
  SKIP=$((SKIP + 1))
}

section() {
  printf '\n\033[1m%s\033[0m\n' "$1"
}

summary() {
  printf '\n────────────────────────────────\n'
  printf 'Tests: \033[32m%d passed\033[0m' "$PASS"
  [[ "$FAIL" -eq 0 ]] || printf ', \033[31m%d failed\033[0m' "$FAIL"
  [[ "$SKIP" -eq 0 ]] || printf ', \033[33m%d skipped\033[0m' "$SKIP"
  printf ' (total %d)\n' "$((PASS + FAIL + SKIP))"
  [[ "$FAIL" -eq 0 ]]
}
